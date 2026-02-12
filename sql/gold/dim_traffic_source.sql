-- SELECT
--     GENERATE_UUID() AS traffic_source_key,  -- UUID surrogate key
--     traffic_source
-- FROM (
--     SELECT DISTINCT traffic_source
--     FROM `prism-486509.silver.events` -- staging/source table
-- ) AS distinct_sources;

-- SELECT
--     TO_HEX(SHA256(traffic_source)) AS traffic_source_key,
--     traffic_source
-- FROM (
--     SELECT DISTINCT traffic_source
--     FROM `prism-486509.silver.events`
--     WHERE traffic_source IS NOT NULL
-- ) AS distinct_sources;

MERGE INTO `prism-486509.gold.dim_traffic_source` AS target
USING (
    SELECT
        TO_HEX(SHA256(traffic_source)) AS traffic_source_key,
        traffic_source
    FROM (
        SELECT DISTINCT traffic_source
        FROM `prism-486509.silver.events`
        WHERE traffic_source IS NOT NULL
    )
) AS source
ON target.traffic_source_key = source.traffic_source_key
WHEN MATCHED THEN
  UPDATE SET target.traffic_source = source.traffic_source
WHEN NOT MATCHED THEN
  INSERT (traffic_source_key, traffic_source)
  VALUES (source.traffic_source_key, source.traffic_source);
