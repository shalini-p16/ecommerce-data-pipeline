-- SELECT
--     GENERATE_UUID() AS page_key,   -- surrogate key as UUID
--     uri AS page_uri,
--     CURRENT_TIMESTAMP() AS created_at
-- FROM (
--     SELECT DISTINCT uri
--     FROM `prism-486509.silver.events`
-- );

SELECT
    TO_HEX(SHA256(uri)) AS page_key,
    uri AS page_uri,
    CURRENT_TIMESTAMP() AS created_at
FROM (
    SELECT DISTINCT uri
    FROM `prism-486509.silver.events`
    WHERE uri IS NOT NULL
);
