-- Dim_Date
CREATE TABLE IF NOT EXISTS prism-486509.gold.Dim_Date (
  date_sk INT64 NOT NULL OPTIONS(description="Surrogate Key for Date Dimension (YYYYMMDD)"),
  full_date DATE NOT NULL OPTIONS(description="Full Date (YYYY-MM-DD)"),
  year INT64 NOT NULL,
  month INT64 NOT NULL,
  month_name STRING NOT NULL,
  day_of_month INT64 NOT NULL,
  day_of_week INT64 NOT NULL,
  day_name STRING NOT NULL,
  quarter INT64 NOT NULL,
  week_of_year INT64 NOT NULL,
  is_weekend BOOLEAN NOT NULL,
  holiday_name STRING OPTIONS(description="Name of holiday, if applicable")
);
