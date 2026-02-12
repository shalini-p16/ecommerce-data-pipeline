-- SELECT
--     -- GENERATE_UUID() AS event_type_key,  -- UUID surrogate key
--     TO_HEX(SHA256(event_type)) AS event_type_key,
--     event_type
-- FROM (
--     SELECT DISTINCT event_type
--     FROM `prism-486509.silver.events`
-- ) AS distinct_events;

MERGE `prism-486509.gold.dim_event_type` AS target
USING (
    SELECT DISTINCT event_type_cleaned AS event_type
    FROM `prism-486509.silver.events`
    WHERE ingestion_date = @run_date
) AS source
ON target.event_type = source.event_type
WHEN NOT MATCHED THEN
  INSERT (event_type_key, event_type)
  VALUES (TO_HEX(SHA256(source.event_type)), source.event_type);

