CREATE TABLE `your_dataset.DIM_EVENT_TYPE` (
  event_type_key STRING NOT NULL DEFAULT GENERATE_UUID(),
  event_type STRING,
  CONSTRAINT pk_event_type_key PRIMARY KEY (event_type_key) NOT ENFORCED
);
