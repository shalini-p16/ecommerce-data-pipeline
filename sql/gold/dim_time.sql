SELECT
  -- Surrogate key
  GENERATE_UUID() AS time_key,
  
  -- Time components (00:00 to 23:59)
  t AS full_time,
  
  -- Hour
  EXTRACT(HOUR FROM t) AS hour_24,
  LPAD(CAST(EXTRACT(HOUR FROM t) AS STRING), 2, '0') AS hour_24_formatted,
  
  -- Hour 12-hour format  
  CASE 
    WHEN EXTRACT(HOUR FROM t) = 0 THEN 12
    ELSE MOD(EXTRACT(HOUR FROM t), 12)
  END AS hour_12,
  FORMAT_TIME('%I', t) AS hour_12_formatted,
  
  -- Minutes
  EXTRACT(MINUTE FROM t) AS minute,
  FORMAT_TIME('%M', t) AS minute_formatted,
  
  -- Seconds
  EXTRACT(SECOND FROM t) AS second,
  FORMAT_TIME('%S', t) AS second_formatted,
  
  -- Time period
  CASE 
    WHEN EXTRACT(HOUR FROM t) < 12 THEN 'AM'
    WHEN EXTRACT(HOUR FROM t) = 12 THEN 'PM'
    ELSE 'PM'
  END AS am_pm,
  
  -- Time of day buckets
  CASE 
    WHEN EXTRACT(HOUR FROM t) BETWEEN 5 AND 11 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM t) BETWEEN 12 AND 17 THEN 'Afternoon'
    WHEN EXTRACT(HOUR FROM t) BETWEEN 18 AND 22 THEN 'Evening'
    ELSE 'Night'
  END AS time_of_day,
  
  -- Business hour flag
  CASE 
    WHEN EXTRACT(HOUR FROM t) BETWEEN 9 AND 17 THEN TRUE
    ELSE FALSE
  END AS is_business_hour

) AS t
ORDER BY t;
