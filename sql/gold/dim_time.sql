-- Dim_Time
CREATE TABLE IF NOT EXISTS prism-486509.gold.Dim_Time (
  time_sk INT64 NOT NULL OPTIONS(description="Surrogate Key for Time Dimension (HHMMSS)"),
  full_time TIME NOT NULL OPTIONS(description="Full Time (HH:MI:SS)"),
  hour INT64 NOT NULL,
  minute INT64 NOT NULL,
  second INT64 NOT NULL,
  ampm STRING NOT NULL OPTIONS(description="AM or PM"),
  time_bucket STRING OPTIONS(description="Time of day bucket (e.g., Morning, Afternoon, Evening)")
);