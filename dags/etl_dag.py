import os
import sys
import yaml
from datetime import datetime

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from src.extract import extract_data

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import (
    BigQueryCreateExternalTableOperator,
    BigQueryInsertJobOperator,
)

PROJECT_ID = "prism-486509"
SQL_BASE_PATH = "/opt/airflow/sql"
CONFIG_PATH = "/opt/airflow/config/tables.yaml"
execution_date = "{{ ds }}"  # Airflow macro: YYYY-MM-DD

default_args = {
    "owner": "airflow",
    "start_date": datetime(2026, 2, 5),
    "retries": 1,
}

with DAG(
    dag_id="ecommerce_etl",
    default_args=default_args,
    schedule_interval="@daily",
    catchup=False,
) as dag:

    # ──────────────────────────────
    # Extract
    # ──────────────────────────────
    extract_task = PythonOperator(
        task_id="extract",
        python_callable=extract_data,
    )

    # ──────────────────────────────
    # Load YAML config
    # ──────────────────────────────
    with open(CONFIG_PATH, "r") as f:
        table_config = yaml.safe_load(f)["tables"]

    for cfg in table_config:
        gcs_uri = f"gs://bronze-data-ecom/{{{{ ds | replace('-', '/') }}}}/{cfg['entity']}.csv"

        # ──────────────────────────────
        # Default external table config
        # ──────────────────────────────
        external_config = {
            "sourceFormat": "CSV",
            "sourceUris": gcs_uri,
            "skipLeadingRows": 1,
            "autodetect": True,  # default for all tables
        }

        # ──────────────────────────────
        # Custom schema for 'orders' only
        # ──────────────────────────────
        if cfg["entity"] == "orders":
            external_config = {
            "sourceFormat": "CSV",
            "autodetect": False, 
            "sourceUris": gcs_uri,
            "skipLeadingRows": 1,
        "schema": {
            "fields": [
                {"name": "order_id", "type": "INT64"},
                {"name": "user_id", "type": "INT64"},
                {"name": "status", "type": "STRING"},
                {"name": "gender", "type": "STRING"},
                {"name": "created_at", "type": "TIMESTAMP"},
                {"name": "returned_at", "type": "TIMESTAMP"},
                {"name": "shipped_at", "type": "TIMESTAMP"},
                {"name": "delivered_at", "type": "TIMESTAMP"},
                {"name": "num_of_item", "type": "INT64"},
            ]
        },
        "csvOptions": {
            "quote": '"',  # BigQuery will handle quoted fields correctly
            "allowJaggedRows": True,  # tolerate missing columns
            "allowQuotedNewlines": True,
           
        },
    }


        create_external = BigQueryCreateExternalTableOperator(
            task_id=f"create_external_{cfg['entity']}",
            table_resource={
                "tableReference": {
                    "projectId": PROJECT_ID,
                    "datasetId": cfg["external_table"].split(".")[0],
                    "tableId": cfg["external_table"].split(".")[1],
                },
                "externalDataConfiguration": external_config,
            },
        )

        silver_sql_path = os.path.join(SQL_BASE_PATH, cfg["silver_sql"])

        silver_transform = BigQueryInsertJobOperator(
            task_id=f"silver_{cfg['entity']}_table",
            configuration={
                "query": {
                    "query": open(silver_sql_path).read(),
                    "useLegacySql": False,
                    "destinationTable": {
                        "projectId": PROJECT_ID,
                        "datasetId": "silver",
                        "tableId": cfg['entity'],
                    },
                    "writeDisposition": "WRITE_TRUNCATE",
                }
            },
        )

        extract_task >> create_external >> silver_transform
