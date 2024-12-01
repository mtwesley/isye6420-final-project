library(dplyr)
library(httr)
library(jsonlite)

# Directories
input_dir <- "noaa_ncei/gsoy-merged"
output_dir <- "noaa_ncei/gsoy-reaggregated"
country_codes_file <- "opendata/country-codes.csv"

# Load existing mappings
station_prefix_to_country_code <- data.frame(
  prefix = c(
    "AJ", "AY", "BC", "BK", "BP", "BU", "CE", "CJ", "CQ", "CS", "CT", "DA", "DR", "EI", "EN", "EU", "EZ",
    "FG", "FP", "FS", "HO", "IC", "IV", "JA", "JN", "JQ", "JU", "KS", "KT", "KU", "LE", "LG", "LH", "LO",
    "MB", "MI", "MJ", "NH", "NN", "NS", "PC", "PO", "PP", "RI", "RM", "RP", "RQ", "SF", "SP", "SU", "SW",
    "TE", "TI", "TS", "TU", "TX", "UC", "UK", "UP", "UV", "VM", "VQ", "WA", "WI", "WQ", "WZ", "ZI"
  ),
  country_code = c(
    "AZ", "AQ", "BW", "BA", "SB", "BG", "LK", "KY", "MP", "CR", "CF", "DK", "DO", "IE", "EE", "FR", "CZ",
    "FR", "FR", "FR", "HN", "IS", "CI", "JP", "NO", "US", "FR", "KR", "AU", "KW", "LB", "EE", "LT", "SK",
    "FR", "MW", "ME", "VU", "NL", "SR", "PN", "PT", "PG", "RS", "MH", "PH", "US", "ZA", "ES", "SD", "SE",
    "FR", "UZ", "TN", "TR", "TM", "NL", "GB", "UA", "BF", "VN", "US", "NA", "MA", "US", "SZ", "ZW"
  )
)

# Check directories
if (!dir.exists(input_dir)) stop("Input directory does not exist: ", input_dir)
if (!dir.exists(output_dir)) dir.create(output_dir, showWarnings = FALSE)

# List files
file_list <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)
unmapped_files <- list()

# Process each file
for (file_path in file_list) {
  cat("Processing:", file_path, "\n")

  # Read data
  data <- read.csv(file_path, stringsAsFactors = FALSE)
  non_numeric_cols <- c("COUNTRY", "DATE")
  numeric_cols <- setdiff(colnames(data), non_numeric_cols)

  # Map country codes
  data <- data %>%
    left_join(station_prefix_to_country_code, by = c("COUNTRY" = "prefix")) %>%
    mutate(COUNTRY = coalesce(country_code, COUNTRY)) %>%
    select(-country_code)

  # Check for unmapped country codes
  unmapped <- data %>% filter(is.na(COUNTRY))
  if (nrow(unmapped) > 0) {
    cat("Unmapped country codes found in:", basename(file_path), "\n")
    unmapped_files <- c(unmapped_files, basename(file_path))
    next
  }

  # Aggregate data
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
      ),
      .groups = "drop"
    ) %>%
    arrange(DATE) %>%
    mutate(across(everything(), ~ ifelse(is.infinite(.), NA, .)))

  # Write to output
  output_file <- file.path(output_dir, basename(file_path))
  write.csv(aggregated_data, output_file, row.names = FALSE, na = "")
  cat("  Written:", output_file, "\n")
}

# Save list of files with unmapped country codes for review
if (length(unmapped_files) > 0) {
  writeLines(unmapped_files, file.path(output_dir, "unmapped_files.txt"))
  cat("Unmapped files saved to unmapped_files.txt\n")
}

cat("Processing complete.\n")
