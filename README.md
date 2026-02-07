# E-commerce Data Pipeline

Designed and implemented a modern **ETL data pipeline** using the **medallion architecture** (bronze → silver → gold layers) to process the **Looker E-commerce BigQuery Dataset** (sourced as CSV files from Kaggle). The pipeline transforms raw e-commerce  data into clean, analytics-ready layers to enable deep insights into:

- Customer website behavior and navigation patterns
- Factors driving purchases and conversion rates
- Product performance and sales trends

## Business Questions Addressed

The pipeline is built to answer the following key business questions:

1. **How do customers behave on the website?**  
   - Navigation patterns and common session flows  
   - Most frequent events (views, clicks, add-to-cart, etc.)  
   - Influence of traffic sources on user actions and conversions

2. **What factors drive customers to make a purchase?**  
   - Behavioral signals that precede purchases  
   - Traffic sources with the highest conversion rates  
   - Event sequences correlated with buying behavior

3. **How are different products performing?**  
   - Top-selling products and underlying reasons  
   - Differences in buyer characteristics by product  
   - Impact of product attributes (price, category, etc.) on sales

## Data Scope & Profiling

**Focused Scope**  
Only data relevant to the business questions above was included. Non-essential tables were excluded during profiling to reduce complexity and ensure alignment with core analytics needs.

**Tables Excluded**  
- `distribution_centers` — logistics-focused, not directly tied to customer behavior or purchases  
- `inventory_items` — physical stock tracking; product details are sufficiently covered by `products` and `order_items`

**Included Sources** (based on TheLook e-commerce schema)  
- Events (user interactions: views, clicks, add-to-cart, etc.)  
- Orders & Order Items (purchases, status, revenue)  
- Users (customer attributes)  
- Products (item details, categories, price)  
- Related dimensions (traffic source, session, browser, etc.)

## Architecture Overview

The pipeline follows the **medallion pattern**:

- **Bronze Layer** — Raw, unprocessed data (full daily snapshots)  
- **Silver Layer** — Cleansed, validated, and lightly transformed data  
- **Gold Layer** — Aggregated, business-ready tables optimized for analytics (e.g., user journeys, conversion funnels, product performance)

### Key Subsystems

1. **Data Profiling**  
   Early assessment of candidate sources for suitability → focused inclusion of relevant tables only.

2. **Change Data Capture (CDC) / Incremental Strategy**  
   - Full daily load for simplicity and reliability  
   - Optional change detection via file hashes or row counts to skip unchanged datasets  
   - Early delta identification before bulk transfer

3. **Extract System**  
   Data landed in GCS with partitioned structure:  
   gs://your-bucket/raw-data/dataset_name=events/date=20260207/file.csv
   gs://your-bucket/raw-data/dataset_name=orders/date=20260207/file.csv


4. **Data Cleansing & Quality**  
Multi-level quality checks:  
- **Column screens**: null checks, range validation, format compliance  
- **Structure screens**: foreign key integrity, hierarchical consistency  
- **Business rule screens**: complex domain-specific validations

5. **Error Handling**  
- Dedicated error event logging schema  
- Support for late-arriving data and slowly changing dimensions (Type 2 updates)  
- Mechanisms to handle facts arriving before dimension context (e.g., placeholder keys, eventual updates)

## Business Matrix

Mapping of business processes to fact tables and key dimensions:

| Business Process                  | Date | User | Session | Event Type | Traffic Source | Page | Product | Location | Browser | Order Status | Business Requirements |
|-----------------------------------|------|------|---------|------------|----------------|------|---------|----------|---------|--------------|------------------------|
| **User Behavior / Interaction** (FACT_EVENTS)     | ✅   | ✅   | ✅      | ✅         | ✅             | ✅   | ❌      | ✅       | ✅      | ❌           | Track events, journeys, funnels, UX optimization |
| **Session / Visit Tracking** (FACT_SESSIONS)      | ✅   | ✅   | ✅      | ❌         | ✅             | ❌   | ❌      | ✅       | ✅      | ❌           | Visit patterns, traffic attribution, engagement |
| **Product Sales** (FACT_ORDER_ITEMS)              | ✅   | ✅   | ❌      | ❌         | ⚪ Optional    | ❌   | ✅      | ✅       | ❌      | ✅           | Revenue, units sold, product performance |
| **Order Fulfillment** (FACT_ORDERS)               | ✅   | ✅   | ❌      | ❌         | ❌             | ❌   | ❌      | ❌       | ❌      | ✅           | Fulfillment KPIs, returns, status tracking |

## Prerequisites

- **Docker Desktop** (recommended) — for local development and testing  
- **Git** — to clone the repository  
- **Python 3.x** — for any helper scripts (e.g., `generate_data.py`)  
- **Google Cloud Platform (GCP) Project** with billing enabled  

**GCP Setup**  
1. Create Cloud Storage buckets:  
- `gs://your-project-id-raw-data` (raw CSVs)  


2. Enable required APIs:  
- BigQuery API  
- Cloud Storage API  
- IAM API, Security Token Service API, Service Account Credentials API  

3. Create a **Service Account** with:  
- Storage Object Admin (on all three buckets)  
- BigQuery Data Editor  
- BigQuery Job User  

4. Download the JSON key → save as `gcp_credentials.json` in the project root

## Getting Started

```bash
# Clone the repo
git clone https://github.com/your-username/ecommerce-data-pipeline.git
cd ecommerce-data-pipeline

# (Optional) Set up virtual environment
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Install dependencies (if using Python-based tools)
pip install -r requirements.txt

# Run the pipeline (example — adapt to your tool: dbt, DLT, Airflow, etc.)
# python main.py
# or
# docker-compose up
## Technologies Used

- **Storage**: Google Cloud Storage (GCS)  
- **Data Warehouse**: Google BigQuery  
- **Orchestration / Transformation**: dbt, Dagster, Apache Airflow, or custom Python (depending on implementation)  
- **Data Formats**:  
  - Raw layer: CSV  
  - Processed / analytic layer: Parquet  
- **Architecture Pattern**: Medallion architecture (bronze → silver → gold)  
- **Cloud Platform**: Google Cloud Platform (GCP)  

## Data Modeling

### Data Modeling Approach

The data warehouse uses a **Kimball dimensional modeling** methodology, optimized for analytical queries and business stakeholder needs.

- **Conceptual Model**  
  The first high-level view of the business system. It identifies the core entities and their relationships without technical details.  
  Focus: What the business cares about (customers, web interactions, purchases, products).

- **Logical Model**  
  Adds structure to the conceptual model by defining:  
  - Primary keys (natural and surrogate)  
  - Attributes (columns)  
  - Relationships between facts and dimensions  
  - (Data types are suggested but not strictly enforced at this stage)

- **Physical Model**  
  The final implementation in the target database (BigQuery). It includes:  
  - Actual data types  
  - Partitioning & clustering keys  
  - Storage format (Parquet in GCS → BigQuery tables)  
  - Optimization for query performance (clustered tables, materialized views where appropriate)

### Proposed Kimball Data Warehouse Architecture

Data flow:  
**Kaggle dataset (CSV) → Google Cloud Storage (raw & partitioned) → BigQuery (bronze → silver → gold)**

The architecture follows the **medallion pattern** with dimensional modeling in the gold layer:

## Future Enhancements

- Implement true **incremental CDC** (change data capture) instead of full daily loads  
- Add **real-time streaming ingestion** using Pub/Sub + Dataflow  
- Develop **Looker** or **Tableau** dashboards connected to the gold layer  
- Introduce **data lineage** and **observability** (e.g., via Monte Carlo, dbt docs, or similar tools)  
- Add automated **data quality monitoring** and alerting  
- Support **schema evolution** and backward-compatible transformations  
- Containerize the pipeline (Docker + Cloud Run or Composer) for easier deployment  