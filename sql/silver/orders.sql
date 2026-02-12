-- SELECT
--     CAST(user_id AS INT64) AS user_id,
--     CAST(order_id AS INT64) AS order_id,
--     status,
--     CAST(gender AS STRING) AS gender,

--     -- Keep as TIMESTAMP
--     TIMESTAMP(created_at) AS created_at,
--     TIMESTAMP(returned_at) AS returned_at,
--     TIMESTAMP(shipped_at) AS shipped_at,
--     TIMESTAMP(delivered_at) AS delivered_at,

--     num_of_item

-- FROM `bronze.orders`
-- WHERE ingestion_date = @run_date;

WITH RankedOrders AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY order_id   -- group duplicates
      ORDER BY created_at DESC  -- pick latest row if duplicates exist
    ) AS rn
  FROM `bronze.orders`
  WHERE ingestion_date = @run_date
)
SELECT
    CAST(user_id AS INT64) AS user_id,
    CAST(order_id AS INT64) AS order_id,
    status,
    CAST(gender AS STRING) AS gender,
    TIMESTAMP(created_at) AS created_at,
    TIMESTAMP(returned_at) AS returned_at,
    TIMESTAMP(shipped_at) AS shipped_at,
    TIMESTAMP(delivered_at) AS delivered_at,
    num_of_item
FROM RankedOrders
WHERE rn = 1;  -- keeps only the first row per order_id
