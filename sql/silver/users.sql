
WITH deduplicated_users AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY id
      ORDER BY SAFE_CAST(created_at AS TIMESTAMP) DESC
    ) AS row_num
  FROM bronze.ext_users
)

SELECT
  -- Identifiers
  SAFE_CAST(id AS INT64) AS user_id,

  -- Name formatting
  CONCAT(first_name, ' ', last_name) AS full_name,
  LOWER(email) AS email_address,

  -- Demographics
  SAFE_CAST(age AS INT64) AS age,
  CASE 
    WHEN SAFE_CAST(age AS INT64) < 18 THEN 'Under 18'
    WHEN SAFE_CAST(age AS INT64) BETWEEN 18 AND 34 THEN '18-34'
    WHEN SAFE_CAST(age AS INT64) BETWEEN 35 AND 54 THEN '35-54'
    ELSE '55+'
  END AS age_group,
  COALESCE(gender, 'Not Specified') AS gender,

  -- Address
  COALESCE(city, 'Unknown City') AS city,
  COALESCE(state, 'Unknown State') AS state,
  country,
  COALESCE(postal_code, 'N/A') AS zip_code,

  -- Metadata
  traffic_source,
  SAFE_CAST(created_at AS TIMESTAMP) AS signup_timestamp,
  CURRENT_TIMESTAMP() AS ingestion_ts,

  -- Data quality
  REGEXP_CONTAINS(email, r'@.+\..+') AS is_valid_email_format

FROM deduplicated_users
WHERE row_num = 1;
