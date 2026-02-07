SELECT
    GENERATE_UUID() AS page_key,   -- surrogate key as UUID
    url AS page_url,
    CURRENT_TIMESTAMP() AS created_at
FROM (
    SELECT DISTINCT url
    FROM silver.web_logs
);