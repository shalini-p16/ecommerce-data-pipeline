
WITH deduplicated_products AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY id
    ) AS row_num
  FROM bronze.ext_products
)

SELECT
  -- Identifiers
  SAFE_CAST(id AS INT64) AS product_id,
  sku,

  -- Descriptive attributes
  COALESCE(name, 'Unnamed Product') AS product_name,
  COALESCE(brand, 'Unknown Brand') AS brand_name,
  COALESCE(category, 'General') AS product_category,
  department,

  -- Pricing
  SAFE_CAST(cost AS NUMERIC) AS unit_cost,
  SAFE_CAST(retail_price AS NUMERIC) AS retail_price,

  -- Distribution
  SAFE_CAST(distribution_center_id AS INT64) AS dist_center_id,

  -- Business checks
  SAFE_CAST(retail_price AS NUMERIC) > SAFE_CAST(cost AS NUMERIC)
    AS is_profitable,

  ROUND(
    SAFE_CAST(retail_price AS NUMERIC) - SAFE_CAST(cost AS NUMERIC),
    2
  ) AS absolute_markup,

  CURRENT_TIMESTAMP() AS ingestion_ts

FROM deduplicated_products
WHERE row_num = 1;
