from airflow.models import Variable
from airflow.providers.google.cloud.hooks.gcs import GCSHook
import os
from kaggle.api.kaggle_api_extended import KaggleApi
from datetime import datetime
import shutil
import pandas as pd

def extract_data(**kwargs):
    """
    Downloads all CSV files from the Kaggle Looker Ecommerce dataset
    and uploads them to Google Cloud Storage in date-partitioned folders:
        bronze/yyyy/mm/dd/<filename>.csv
    
    Adds an 'ingestion_date' column to each CSV for BigQuery partitioning.
    """
    
    # ── 1. Get Kaggle credentials ─────────────────────────────────────
    kaggle_username = Variable.get("kaggle_username", default_var=None)
    kaggle_key = Variable.get("kaggle_key", default_var=None)

    if not kaggle_username or not kaggle_key:
        raise ValueError(
            "Kaggle credentials missing. Set 'kaggle_username' and 'kaggle_key' "
            "in Airflow Variables."
        )

    # ── 2. Download dataset ─────────────────────────────────────────
    print("Starting Kaggle dataset download...")
    api = KaggleApi()
    api.authenticate()

    local_download_path = '/tmp/bronze_temp'
    if os.path.exists(local_download_path):
        shutil.rmtree(local_download_path)
    os.makedirs(local_download_path, exist_ok=True)

    api.dataset_download_files(
        dataset='mustafakeser4/looker-ecommerce-bigquery-dataset',
        path=local_download_path,
        unzip=True,
        quiet=False
    )

    # ── 3. Initialize GCS hook ──────────────────────────────────────
    gcs_conn_id = 'google_cloud_default'
    gcs_bucket = 'bronze-data-ecom'
    gcs_hook = GCSHook(gcp_conn_id=gcs_conn_id)

    # ── 4. Get execution_date ────────────────────────────────────
    execution_date = kwargs.get('execution_date') or datetime.today()
    ingestion_date_str = execution_date.strftime('%Y-%m-%d')  # for folder partition
    print(f"Adding ingestion_date={ingestion_date_str} to CSVs and uploading...")

    uploaded_count = 0

    # ── 5. Process and upload CSVs ───────────────────────────────
    for root, _, files in os.walk(local_download_path):
        for file_name in files:
            if file_name.lower().endswith('.csv'):
                local_file_path = os.path.join(root, file_name)
                
                # Read CSV
                df = pd.read_csv(local_file_path)

                # ── Fix events.user_id if needed ─────────────────
                if file_name.startswith("events") and 'user_id' in df.columns:
                    df['user_id'] = pd.to_numeric(df['user_id'], errors='coerce')

                # ── Add ingestion_date column ─────────────────────
                df['ingestion_date'] = ingestion_date_str

                # Save back to CSV
                df.to_csv(local_file_path, index=False)

                # GCS object path (still partitioned in folder for readability)
                gcs_object_name = f"{file_name.split('.')[0]}/ingestion_date={ingestion_date_str}/{file_name}"

                try:
                    gcs_hook.upload(
                        bucket_name=gcs_bucket,
                        object_name=gcs_object_name,
                        filename=local_file_path
                    )
                    print(f"Uploaded: {gcs_object_name}")
                    uploaded_count += 1
                except Exception as e:
                    print(f"Failed to upload {file_name}: {e}")
                    raise

    print(f"Extraction complete. Uploaded {uploaded_count} CSV files to GCS.")
