WITH deduplicated_centers AS (
  -- Step 1: Ensure uniqueness (safety check)
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) as row_num
  FROM
    `prism-486509.ecom_dataset.distribution_centers`
)
SELECT
  -- Step 2: Identifiers & Renaming
  id AS dist_center_id,
  name AS center_name,


  -- Step 3: Geographic Enrichment
  -- Extracting the state code (last 2 characters) from names like "Los Angeles CA"
  TRIM(SUBSTR(name, -2)) AS state_code,


  -- Step 4: Coordinate Accuracy
  CAST(latitude AS FLOAT64) AS latitude,
  CAST(longitude AS FLOAT64) AS longitude,


  -- Step 5: Handling Potential Nulls (Best practice)
  COALESCE(name, 'Unknown Location') AS clean_center_name


FROM
  deduplicated_centers
WHERE
  row_num = 1
ORDER BY 
  dist_center_id;
