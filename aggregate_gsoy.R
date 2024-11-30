library(dplyr)

# Directories
input_dir <- "gsoy-merged"
output_dir <- "gsoy-aggregated"

if (!dir.exists(input_dir)) stop("Input directory does not exist: ", input_dir)
if (!dir.exists(output_dir)) dir.create(output_dir, showWarnings = FALSE)

# List all files in the input directory
file_list <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)

# Process each file
for (file_path in file_list) {
  cat("Processing file:", file_path, "\n")

  # Load data into a dataframe
  data <- read.csv(file_path, stringsAsFactors = FALSE)

  # Exclude non-numeric columns for aggregation
  non_numeric_cols <- c("COUNTRY", "DATE")
  numeric_cols <- setdiff(colnames(data), non_numeric_cols)

  # Aggregate data by DATE
  aggregated_data <- data %>%
    group_by(DATE) %>%
    summarize(
      across(
        all_of(numeric_cols),
        list(
          MIN = ~ min(., na.rm = TRUE),
          MAX = ~ max(., na.rm = TRUE),
          MEAN = ~ mean(., na.rm = TRUE),
          SD = ~ sd(., na.rm = TRUE)
        ),
        .names = "{.col}_{.fn}"
      )
    ) %>%
    arrange(DATE) # Sort by DATE

  # Save the aggregated data to the output directory
  output_file <- file.path(output_dir, basename(file_path))
  write.csv(aggregated_data, output_file, row.names = FALSE, na = "")
  cat("  Aggregated file written:", output_file, "\n")
}

cat("All files processed.\n")
