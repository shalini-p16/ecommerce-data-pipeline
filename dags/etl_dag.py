import sys
import os
import yaml
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup
from google.cloud import bigquery
import logging
from airflow.providers.google.cloud.operators.bigquery import (
    BigQueryCreateEmptyTableOperator,
    BigQueryInsertJobOperator,
    BigQueryCheckOperator,
)
from airflow.providers.google.cloud.hooks.gcs import GCSHook
from airflow.models import Variable

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from src.extract import extract_data

# ──────────────────────────────────────────────
# CONFIG
# ──────────────────────────────────────────────
PROJECT_ID = os.getenv("GCP_PROJECT_ID", "prism-486509")
LOCATION = os.getenv("GCP_LOCATION", "europe-west1")
SQL_BASE_PATH = "/opt/airflow/sql"
CONFIG_PATH = "/opt/airflow/config/tables.yaml"
GCS_BRONZE_BUCKET = "bronze-data-ecom"

default_args = {
    "owner": "data_engineering",
    "start_date": datetime(2026, 2, 5),
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "email": ["data-team@company.com"],
    "email_on_failure": True,
    "email_on_retry": False,
    "depends_on_past": False,
}

# ──────────────────────────────────────────────
# HELPER FUNCTIONS
# ──────────────────────────────────────────────
def load_bronze_with_ingestion_date(entity: str, ds: str, project_id: str, location: str = "US", **kwargs):
    client = bigquery.Client(project=project_id)
    with open(CONFIG_PATH) as f:
        cfg = yaml.safe_load(f)

    table_cfg = next((t for t in cfg.get("bronze_tables", []) if t["entity"] == entity), None)
    if not table_cfg:
        raise ValueError(f"Entity '{entity}' not found in YAML bronze_tables")

    table_id = table_cfg.get("bronze_table", f"{project_id}.bronze.{entity}")
    partition_field = table_cfg.get("partition_field")
    schema_cfg = table_cfg.get("schema", [])
    if not schema_cfg:
        raise ValueError(f"No schema defined for entity {entity}")

    # Create table if missing
    columns_sql = ", ".join([f"{col['name']} {col['type']}" for col in schema_cfg])
    create_sql = f"CREATE TABLE IF NOT EXISTS {table_id} ({columns_sql})"
    if partition_field:
        create_sql += f" PARTITION BY {partition_field}"
    logging.info(f"Creating table if not exists: {table_id}")
    client.query(create_sql).result()

    # Delete partition
    if partition_field:
        delete_sql = f"DELETE FROM {table_id} WHERE {partition_field} = DATE('{ds}')"
        logging.info(f"Deleting partition {ds} from {table_id}")
        client.query(delete_sql).result()

    # Load CSV from GCS
    gcs_bucket = Variable.get("bronze_gcs_bucket", default_var="bronze-data-ecom")
    gcs_uri = f"gs://{gcs_bucket}/{entity}/ingestion_date={ds}/*.csv"
    load_job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        schema=[bigquery.SchemaField(col['name'], col['type']) for col in schema_cfg],
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        time_partitioning=bigquery.TimePartitioning(field=partition_field) if partition_field else None,
    )
    load_job = client.load_table_from_uri(gcs_uri, table_id, job_config=load_job_config)
    load_job.result()
    logging.info(f"Loaded {load_job.output_rows} rows into {table_id}")

# ──────────────────────────────────────────────
# DAG
# ──────────────────────────────────────────────
with DAG(
    dag_id="ecommerce_etl_v2",
    default_args=default_args,
    description="E-commerce ETL (Bronze → Silver → Gold)",
    schedule_interval="0 13 * * *",
    catchup=False,
    max_active_runs=1,
    tags=["ecommerce", "medallion", "production"],
) as dag:

    with open(CONFIG_PATH, "r") as f:
        config = yaml.safe_load(f)
    bronze_config = config.get("bronze_tables", [])
    silver_config = config.get("silver_tables", [])
    gold_config = config.get("gold_tables", [])

    # ────────────── EXTRACT ──────────────
    with TaskGroup("extract") as extract_group:
        extract_task = PythonOperator(
            task_id="extract_from_kaggle",
            python_callable=extract_data,
        )

    # ────────────── BRONZE ──────────────
    bronze_tasks = []
    for cfg in bronze_config:
        entity = cfg["entity"]
        load_task = PythonOperator(
            task_id=f"load_{entity}",
            python_callable=load_bronze_with_ingestion_date,
            op_kwargs={"entity": entity, "ds": "{{ ds }}", "project_id": PROJECT_ID, "location": LOCATION},
            provide_context=True,
        )
        check_task = BigQueryCheckOperator(
            task_id=f"check_{entity}_loaded",
            sql=f"SELECT COUNT(*) > 0 FROM {PROJECT_ID}.bronze.{entity} WHERE ingestion_date = DATE('{{{{ ds }}}}')",
            use_legacy_sql=False,
            location=LOCATION,
        )
        load_task >> check_task
        extract_task >> load_task
        bronze_tasks.append(check_task)

    # ────────────── SILVER ──────────────
    silver_entity_tasks = {}
    silver_tasks = []

    with TaskGroup("silver_setup") as silver_setup_group:
        for cfg in silver_config:
            entity = cfg["entity"]
            schema = cfg.get("schema", [])
            partition = cfg.get("partition")
            if not schema:
                continue
            create_table = BigQueryCreateEmptyTableOperator(
                task_id=f"create_silver_{entity}",
                project_id=PROJECT_ID,
                dataset_id="silver",
                table_id=entity,
                schema_fields=schema,
                exists_ok=True,
                time_partitioning={"type": partition["type"], "field": partition["field"]} if partition else None,
            )
            silver_entity_tasks[entity] = {"create": create_table, "transform": None}

    with TaskGroup("silver_layer") as silver_group:
        for cfg in silver_config:
            entity = cfg["entity"]
            sql_path = os.path.join(SQL_BASE_PATH, cfg["silver_sql"])
            if not os.path.exists(sql_path):
                continue
            dataset_id, table_id = cfg.get("silver_table", f"silver.{entity}").split(".")
            transform_task = BigQueryInsertJobOperator(
                task_id=f"transform_{entity}",
                location=LOCATION,
                configuration={
                    "query": {
                        "query": open(sql_path).read(),
                        "useLegacySql": False,
                        "destinationTable": {"projectId": PROJECT_ID, "datasetId": dataset_id, "tableId": table_id},
                        "writeDisposition": "WRITE_TRUNCATE",
                        "createDisposition": "CREATE_IF_NEEDED",
                        "queryParameters": [{"name": "run_date", "parameterType": {"type": "DATE"}, "parameterValue": {"value": "{{ ds }}"}}],
                    }
                },
            )
            if entity in silver_entity_tasks:
                silver_entity_tasks[entity]["transform"] = transform_task
                silver_tasks.append(transform_task)

    silver_done = EmptyOperator(task_id="silver_done")

    for tasks in silver_entity_tasks.values():
        create = tasks["create"]
        transform = tasks["transform"]
        if create and transform:
            create >> transform >> silver_done
        elif transform:
            transform >> silver_done

    # ────────────── GOLD ──────────────
    gold_tasks = []
    with TaskGroup("gold_layer") as gold_group:
        table_creation_tasks = []
        dimensions = []
        facts = []

        # Create gold tables
        for gold in gold_config:
            if "schema" not in gold or not gold["schema"]:
                continue
            table_id = gold.get("destination", gold["name"])
            create_table = BigQueryCreateEmptyTableOperator(
                task_id=f"create_{table_id}",
                project_id=PROJECT_ID,
                dataset_id="gold",
                table_id=table_id,
                schema_fields=gold["schema"],
                exists_ok=True,
                location=LOCATION,
            )
            table_creation_tasks.append(create_table)

        # Load dimensions
        dimensions = [g for g in gold_config if g.get("destination", g["name"]).startswith("dim_")]
        dim_tasks = []
        for gold in dimensions:
            sql_path = os.path.join(SQL_BASE_PATH, gold["sql"])
            if not os.path.exists(sql_path):
                continue
            table_id = gold.get("destination", gold["name"])
            with open(sql_path) as f:
                sql_text = f.read()
            sql_upper = sql_text.upper()
            is_dml = any(k in sql_upper for k in ["MERGE", "INSERT", "UPDATE", "DELETE"])
            config_job = {"query": {"query": sql_text, "useLegacySql": False}}
            if not is_dml:
                config_job["query"]["destinationTable"] = {"projectId": PROJECT_ID, "datasetId": "gold", "tableId": table_id}
                config_job["query"]["writeDisposition"] = "WRITE_TRUNCATE"
            config_job["query"]["queryParameters"] = [{"name": "run_date", "parameterType": {"type": "DATE"}, "parameterValue": {"value": "{{ ds }}"}}]
            task = BigQueryInsertJobOperator(task_id=f"load_{gold['name']}", location=LOCATION, configuration=config_job)
            dim_tasks.append(task)
            gold_tasks.append(task)

        dims_done = EmptyOperator(task_id="dimensions_loaded")
        last_create = table_creation_tasks[-1] if table_creation_tasks else EmptyOperator(task_id="no_tables_to_create")
        if dim_tasks:
            last_create >> dim_tasks[0]
            for i in range(len(dim_tasks) - 1):
                dim_tasks[i] >> dim_tasks[i + 1]
            last_dim = dim_tasks[-1]
        else:
            last_dim = EmptyOperator(task_id="no_dims_to_load")
        last_dim >> dims_done

        # Load facts
        facts = [g for g in gold_config if g.get("destination", g["name"]).startswith("fact_")]
        fact_tasks = []
        for gold in facts:
            sql_path = os.path.join(SQL_BASE_PATH, gold["sql"])
            if not os.path.exists(sql_path):
                continue
            table_id = gold.get("destination", gold["name"])
            task = BigQueryInsertJobOperator(
                task_id=f"load_{gold['name']}",
                location=LOCATION,
                configuration={
                    "query": {
                        "query": open(sql_path).read(),
                        "useLegacySql": False,
                        "destinationTable": {"projectId": PROJECT_ID, "datasetId": "gold", "tableId": table_id},
                        "writeDisposition": "WRITE_TRUNCATE",
                        "queryParameters": [{"name": "run_date", "parameterType": {"type": "DATE"}, "parameterValue": {"value": "{{ ds }}"}}],
                    }
                },
            )
            fact_tasks.append(task)
            gold_tasks.append(task)
        if fact_tasks:
            dims_done >> fact_tasks[0]
            for i in range(len(fact_tasks) - 1):
                fact_tasks[i] >> fact_tasks[i + 1]

    # ────────────── DATA QUALITY ──────────────
    with TaskGroup("data_quality") as dq_group:
        check_dim_users_duplicates = BigQueryCheckOperator(
            task_id="check_dim_users_duplicates",
            sql=f"""
                SELECT COUNT(*) = 0
                FROM (
                    SELECT user_key, COUNT(*) AS cnt
                    FROM {PROJECT_ID}.gold.dim_users
                    GROUP BY user_key
                    HAVING cnt > 1
                )
            """,
            use_legacy_sql=False,
            location=LOCATION,
        )

    # ────────────── DEPENDENCIES ──────────────
    extract_group >> bronze_tasks
    for b, s in zip(bronze_tasks, silver_tasks):
        b >> s
    silver_done >> gold_group >> dq_group
