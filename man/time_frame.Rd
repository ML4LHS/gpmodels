% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gpmodels.R
\name{time_frame}
\alias{time_frame}
\title{Define wizard frame}
\usage{
time_frame(
  fixed_data,
  temporal_data,
  fixed_id = "id",
  fixed_start = NULL,
  fixed_end = NULL,
  temporal_id = "id",
  temporal_time = "time",
  temporal_variable = "variable",
  temporal_value = "value",
  temporal_category = temporal_variable,
  step = NULL,
  max_length = NULL,
  output_folder = NULL,
  create_folder = FALSE,
  save_time_frame = TRUE,
  chunk_size = NULL,
  numeric_threshold = 0.5
)
}
\description{
Define wizard frame
}
