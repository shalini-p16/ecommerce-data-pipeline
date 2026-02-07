CREATE TABLE `your_dataset.DIM_USER` (
  user_key STRING NOT NULL DEFAULT GENERATE_UUID(),   -- surrogate key (UUID)
  user_id INT64,                                      -- natural/business key
  gender STRING,
  age INT64,
  city STRING,
  state STRING,
  country STRING,
  traffic_source STRING,
  effective_from DATE,
  effective_to DATE,
  is_current BOOL,
  CONSTRAINT pk_user_key PRIMARY KEY (user_key) NOT ENFORCED
);
