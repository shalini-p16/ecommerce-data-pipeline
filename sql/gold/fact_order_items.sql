-- -- SELECT
--   -- Deterministic surrogate key for fact_order_items
--   TO_HEX(SHA256(CAST(oi.order_item_id AS STRING))) AS order_item_key,

--   -- Foreign Keys from Dimension Tables
--   o.order_key,
--   u.user_key,
--   p.product_key,
--   os.order_status_key,
--   dd_created.date_key AS order_date_key,
--   dd_shipped.date_key AS shipped_date_key,
--   dd_delivered.date_key AS delivered_date_key,
--   dd_returned.date_key AS returned_date_key,


-- FROM
--   `prism-486509.silver.order_items` AS oi

-- LEFT JOIN `prism-486509.gold.fact_orders` AS o
--   ON CAST(oi.order_id AS STRING) = CAST(o.order_id AS STRING)

-- LEFT JOIN `prism-486509.gold.dim_users` AS u
--   ON CAST(oi.user_id AS STRING) = CAST(u.user_id AS STRING)

-- LEFT JOIN `prism-486509.gold.dim_products` AS p
--   ON oi.product_id = p.product_id

-- LEFT JOIN `prism-486509.gold.dim_order_status` AS os
--   ON oi.order_status = os.order_status

-- LEFT JOIN `prism-486509.gold.dim_date` AS dd_created
--   ON DATE(oi.order_created_at) = dd_created.date

-- LEFT JOIN `prism-486509.gold.dim_date` AS dd_shipped
--   ON DATE(oi.shipped_at) = dd_shipped.date

-- LEFT JOIN `prism-486509.gold.dim_date` AS dd_delivered
--   ON DATE(oi.delivered_at) = dd_delivered.date

-- LEFT JOIN `prism-486509.gold.dim_date` AS dd_returned
--   ON DATE(oi.returned_at) = dd_returned.date;

SELECT
  -- Deterministic surrogate key for fact_order_items
  TO_HEX(SHA256(CAST(oi.order_item_id AS STRING))) AS order_item_key,

  -- Foreign Keys from Dimension Tables
  o.order_key,
  u.user_key,
  p.product_key,
  os.order_status_key,
  dd_created.date_key AS order_date_key,
  dd_shipped.date_key AS shipped_date_key,
  dd_delivered.date_key AS delivered_date_key,
  dd_returned.date_key AS returned_date_key,

  -- Optional raw business keys for auditing
  oi.order_id,
  oi.user_id,
  oi.product_id,
  oi.order_item_id,

  -- Fact measures
  oi.item_sale_price,

--   -- Boolean flags converted to numeric for aggregation
--   CASE WHEN oi.is_fully_completed THEN 1 ELSE 0 END AS is_fully_completed,
--   CASE WHEN oi.was_returned THEN 1 ELSE 0 END AS was_returned

FROM
  `prism-486509.silver.order_items` AS oi

LEFT JOIN `prism-486509.gold.fact_orders` AS o
  ON CAST(oi.order_id AS STRING) = CAST(o.order_id AS STRING)

LEFT JOIN `prism-486509.gold.dim_users` AS u
  ON CAST(oi.user_id AS STRING) = CAST(u.user_id AS STRING)

LEFT JOIN `prism-486509.gold.dim_products` AS p
  ON oi.product_id = p.product_id

LEFT JOIN `prism-486509.gold.dim_order_status` AS os
  ON oi.order_status = os.order_status

LEFT JOIN `prism-486509.gold.dim_date` AS dd_created
  ON DATE(oi.order_created_at) = dd_created.date

LEFT JOIN `prism-486509.gold.dim_date` AS dd_shipped
  ON DATE(oi.shipped_at) = dd_shipped.date

LEFT JOIN `prism-486509.gold.dim_date` AS dd_delivered
  ON DATE(oi.delivered_at) = dd_delivered.date

LEFT JOIN `prism-486509.gold.dim_date` AS dd_returned
  ON DATE(oi.returned_at) = dd_returned.date;
