# Use the same base version as your current image
FROM apache/airflow:2.8.1

# Switch to airflow user (important – pip installs as root will fail later)
USER airflow

# Copy and install your requirements
COPY requirements.txt /requirements.txt

# Install packages (using constraints for Airflow compatibility)
RUN pip install --no-cache-dir -r /requirements.txt



