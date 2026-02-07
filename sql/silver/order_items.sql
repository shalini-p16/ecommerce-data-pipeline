
WITH deduplicated_order_items AS (
  -- Step 1: Ensure uniqueness by item ID
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY created_at DESC) as row_num
  FROM
    `bronze.ext_order_items`
)
SELECT
  -- Step 2: Identifiers & Renaming
  id AS order_item_id,
  order_id,
  user_id,
  product_id,
  inventory_item_id,

  -- Step 3: Financial Standardization
  CAST(sale_price AS NUMERIC) AS item_sale_price,

  -- Step 4: Status Cleaning
  INITCAP(status) AS order_status, -- Ensures "Shipped" instead of "shipped"

  -- Step 5: Timestamps
  created_at AS order_created_at,
  shipped_at,
  delivered_at,
  returned_at,

  -- Step 6: Logical Flags for Easier Reporting
  CASE 
    WHEN status = 'Complete' THEN TRUE 
    ELSE FALSE 
  END AS is_fully_completed,

  CASE 
    WHEN returned_at IS NOT NULL THEN TRUE 
    ELSE FALSE 
  END AS was_returned

FROM
  deduplicated_order_items
WHERE
  row_num = 1
ORDER BY 
  order_created_at DESC;


