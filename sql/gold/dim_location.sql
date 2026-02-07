CREATE TABLE `your_dataset.DIM_LOCATION` (
  location_key STRING NOT NULL DEFAULT GENERATE_UUID(),   -- UUID surrogate key
  city STRING,
  state STRING,
  postal_code STRING,
  country STRING,
  latitude FLOAT64,
  longitude FLOAT64,
  CONSTRAINT pk_location_key PRIMARY KEY (location_key) NOT ENFORCED
);
