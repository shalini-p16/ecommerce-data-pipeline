WITH deduplicated_data AS (
  -- Step 1: Deduplicate using a Unique ID (id) and keeping the latest record
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY created_at DESC) as row_num
  FROM
    `prism-486509.ecom_dataset.inventory_items`
)
SELECT
  -- Step 2: Rename columns for clarity
  id AS inventory_item_id,
  product_id,

  -- Step 3: Explicit data type casting (e.g., using NUMERIC for financial precision)
  CAST(cost AS NUMERIC) AS unit_cost,
  CAST(product_retail_price AS NUMERIC) AS retail_price,

  -- Step 4: Handle Nulls using COALESCE with meaningful defaults
  COALESCE(product_name, 'Unknown Product') AS product_name,
  COALESCE(product_brand, 'Generic') AS product_brand,
  COALESCE(product_category, 'Uncategorized') AS product_category,

  -- Leaving sold_at as is, or you could use a placeholder date
  sold_at,
  created_at,

  product_department AS department,
  product_sku AS sku,
  product_distribution_center_id AS dist_center_id,

  -- Step 5: Basic Validation Flag (Example: Check if retail price is valid)
  CASE 
    WHEN product_retail_price > 0 THEN TRUE 
    ELSE FALSE 
  END AS is_price_valid

FROM
  deduplicated_data
WHERE
  row_num = 1 -- Only keep the unique/latest record
ORDER BY 
  created_at DESC;
