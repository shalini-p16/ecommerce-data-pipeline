CREATE TABLE `your_dataset.DIM_BROWSER` (
  browser_key STRING NOT NULL DEFAULT GENERATE_UUID(),  -- UUID surrogate key
  browser_name STRING,
  CONSTRAINT pk_browser_key PRIMARY KEY (browser_key) NOT ENFORCED
);
