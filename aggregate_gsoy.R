library(dplyr)

# input_dir <- "noaa_ncei/gsoy-merged"
# output_dir <- "noaa_ncei/gsoy-aggregated"

# reaggregate data
input_dir <- "noaa_ncei/gsoy-remerged"
output_dir <- "noaa_ncei/gsoy-reaggregated"

if (!dir.exists(input_dir)) stop("Input directory does not exist: ", input_dir)
if (!dir.exists(output_dir)) dir.create(output_dir, showWarnings = FALSE)

file_list <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)

for (file_path in file_list) {
  cat("Processing:", file_path, "\n")

  data <- read.csv(file_path, stringsAsFactors = FALSE)
  non_numeric_cols <- c("COUNTRY", "DATE")
  numeric_cols <- setdiff(colnames(data), non_numeric_cols)

  aggregated_data <- data %>%
    group_by(COUNTRY, DATE) %>%
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
    arrange(DATE) %>%
    mutate(across(everything(), ~ ifelse(is.infinite(.), NA, .)))

  output_file <- file.path(output_dir, basename(file_path))
  write.csv(aggregated_data, output_file, row.names = FALSE, na = "")
  cat("  Written:", output_file, "\n")
}

cat("Processing complete.\n")
