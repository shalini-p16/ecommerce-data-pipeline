SELECT
  -- Surrogate key
  GENERATE_UUID() AS date_key,

  -- Full date
  d AS date,

  -- Year
  EXTRACT(YEAR FROM d) AS year,

  -- Quarter
  EXTRACT(QUARTER FROM d) AS quarter,
  FORMAT_DATE('%Y-Q%Q', d) AS year_quarter,

  -- Month
  EXTRACT(MONTH FROM d) AS month,
  FORMAT_DATE('%Y-%m', d) AS year_month,
  FORMAT_DATE('%B', d) AS month_name,

  -- Week
  EXTRACT(WEEK FROM d) AS week_of_year,
  FORMAT_DATE('%Y-W%U', d) AS year_week,

  -- Day
  EXTRACT(DAY FROM d) AS day_of_month,
  EXTRACT(DAYOFYEAR FROM d) AS day_of_year,
  FORMAT_DATE('%A', d) AS day_name,
  FORMAT_DATE('%w', d) AS day_of_week,  -- 0=Sunday, 1=Monday, ...

  -- Weekend vs weekday
  CASE
    WHEN FORMAT_DATE('%A', d) IN ('Saturday', 'Sunday') THEN 0
    ELSE 1
  END AS is_weekday,

  -- Holiday / special flags (extend as needed)
  FALSE AS is_holiday,
  FALSE AS is_business_day

FROM UNNEST(
  GENERATE_DATE_ARRAY(
    '2010-01-01',   -- start date
    '2030-12-31',   -- end date
    INTERVAL 1 DAY
  )
) AS d
ORDER BY d;
