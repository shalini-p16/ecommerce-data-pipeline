from airflow.models import Variable
from airflow.providers.google.cloud.hooks.gcs import GCSHook
import os
from kaggle.api.kaggle_api_extended import KaggleApi
from datetime import datetime
import shutil

def extract_data(**kwargs):
    """
    Downloads all CSV files from the Kaggle Looker Ecommerce dataset
    and uploads them to Google Cloud Storage in date-partitioned folders:
        bronze/yyyy/mm/dd/<filename>.csv
    
    Partition is based on Airflow execution_date.
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
    gcs_conn_id = 'google_cloud_default'  # Airflow connection ID for GCS
    gcs_bucket = 'bronze-data-ecom'
    gcs_hook = GCSHook(gcp_conn_id=gcs_conn_id)

    # ── 4. Use execution_date for partition ─────────────────────────
    execution_date = kwargs.get('execution_date')  # Provided by Airflow
    if not execution_date:
        execution_date = datetime.today()
    
    date_prefix = execution_date.strftime('%Y/%m/%d/')
    print(f"Uploading CSVs to GCS under partition: {date_prefix}")

    uploaded_count = 0

    # ── 5. Upload CSVs to GCS ───────────────────────────────────────
    for root, _, files in os.walk(local_download_path):
        for file_name in files:
            if file_name.lower().endswith('.csv'):
                local_file_path = os.path.join(root, file_name)
                gcs_object_name = f"{date_prefix}{file_name}"

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

    print(f"Extraction complete. Uploaded {uploaded_count} CSV files to GCS under {date_prefix}")
