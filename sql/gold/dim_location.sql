-- SELECT
--     GENERATE_UUID() AS location_key,       -- UUID surrogate key
--     city,
--     state,
--     postal_code
  
-- FROM (
--     SELECT DISTINCT 
--         city,
--         state,
--         postal_code,
--     FROM `prism-486509.silver.events`  -- source table
-- ) AS distinct_locations;
-- SELECT
--     TO_HEX(
--       SHA256(
--         CONCAT(
--           COALESCE(city, ''), '|',
--           COALESCE(state, ''), '|',
--           COALESCE(postal_code, '')
--         )
--       )
--     ) AS location_key,
--     city,
--     state,
--     postal_code
-- FROM (
--     SELECT DISTINCT
--         city,
--         state,
--         postal_code
--     FROM `prism-486509.silver.events`
--     WHERE city IS NOT NULL
--        OR state IS NOT NULL
--        OR postal_code IS NOT NULL
-- ) AS distinct_locations;


MERGE INTO `prism-486509.gold.dim_location` AS target
USING (
    SELECT
        TO_HEX(
          SHA256(
            CONCAT(
              COALESCE(city, ''), '|',
              COALESCE(state, ''), '|',
              COALESCE(postal_code, '')
            )
          )
        ) AS location_key,
        city,
        state,
        postal_code
    FROM (
        SELECT DISTINCT
            city,
            state,
            postal_code
        FROM `prism-486509.silver.events`
        WHERE city IS NOT NULL OR state IS NOT NULL OR postal_code IS NOT NULL
    )
) AS source
ON target.location_key = source.location_key
WHEN MATCHED THEN
  UPDATE SET
    target.city = source.city,
    target.state = source.state,
    target.postal_code = source.postal_code
WHEN NOT MATCHED THEN
  INSERT (location_key, city, state, postal_code)
  VALUES (source.location_key, source.city, source.state, source.postal_code);
