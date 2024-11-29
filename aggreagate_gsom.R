library(dplyr)
library(readr)

input_dir <- "gsom-merged"
output_dir <- "gsom-aggregated"

dir.create(output_dir, showWarnings = FALSE)

# List all files for countries
file_list <- list.files(input_dir, pattern = "_sorted\\.csv$", full.names = TRUE)

# Process each country file
for (file in file_list) {
  # Extract the country code from the file name
  country_code <- substr(basename(file), 1, 2)

  # Read the country file
  data <- read_csv(file, show_col_types = FALSE)

  # Ensure columns are in lowercase for consistency
  colnames(data) <- tolower(colnames(data))

  # Parse date if necessary and extract year-month
  if ("date" %in% colnames(data)) {
    data <- data %>%
      mutate(year_month = format(as.Date(date, format = "%Y-%m-%d"), "%Y-%m"))
  } else {
    stop("The data does not have a 'date' column. Please verify your files.")
  }

  # Select numeric columns for aggregation (exclude metadata columns)
  metadata_cols <- c("station", "country", "latitude", "longitude", "elevation", "date", "year_month")
  variable_cols <- setdiff(colnames(data), metadata_cols)

  # Group by year-month and compute min, max, and average for all variables
  aggregated <- data %>%
    group_by(year_month) %>%
    summarise(across(
      all_of(variable_cols),
      list(
        min = ~ min(.x, na.rm = TRUE),
        max = ~ max(.x, na.rm = TRUE),
        avg = ~ mean(.x, na.rm = TRUE)
      ),
      .names = "{.col}_{.fn}"
    )) %>%
    ungroup()

  # Save the aggregated data for this country
  output_file <- file.path(output_dir, paste0("gsom_", country_code, ".csv"))
  write_csv(aggregated, output_file)

  cat("Processed and saved:", output_file, "\n")
}

# Print completion message
cat("Aggregation completed for all countries.\n")