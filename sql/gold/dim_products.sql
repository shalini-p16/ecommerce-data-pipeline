MERGE `prism-486509.gold.dim_products` AS target
USING (
  SELECT 
    product_id,
    product_name,
    brand_name,
    product_category,
    department,
    sku,
    retail_price,
    dist_center_id
  FROM `prism-486509.silver.products`
) AS source
ON target.product_id = source.product_id
   AND target.is_current = TRUE

-- Update old version if any attribute changed
WHEN MATCHED AND (
  target.product_name <> source.product_name OR
  target.brand_name <> source.brand_name OR
  target.product_category <> source.product_category OR
  target.department <> source.department OR
  target.sku <> source.sku OR
  target.retail_price <> source.retail_price OR
  COALESCE(target.dist_center_id, 0) <> COALESCE(source.dist_center_id, 0)
) THEN
  UPDATE SET 
    effective_to = CURRENT_DATE(),
    is_current = FALSE

-- Insert new version for new product or changed product
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    product_key,
    product_id,
    product_name,
    brand_name,
    product_category,
    department,
    sku,
    retail_price,
    dist_center_id,
    effective_from,
    effective_to,
    is_current
  )
  VALUES (
    TO_HEX(SHA256(CONCAT(CAST(source.product_id AS STRING), '|', CAST(CURRENT_DATE() AS STRING)))),  -- deterministic SCD2 key
    source.product_id,
    source.product_name,
    source.brand_name,
    source.product_category,
    source.department,
    source.sku,
    source.retail_price,
    source.dist_center_id,
    CURRENT_DATE(),
    DATE('9999-12-31'),
    TRUE
  );
