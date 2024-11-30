library(dplyr)

variables <- c(
  "COUNTRY", "DATE",
  "AWND", "CDSD", "CLDD", "DP01", "DP10", "DP1X", "DSND", "DSNW", "DT00", "DT32",
  "DX32", "DX70", "DX90", "DYFG", "DYHF", "DYTS", "EMNT", "EMSD", "EMSN", "EMXP",
  "EMXT", "EVAP", "FZF0", "FZF1", "FZF2", "FZF3", "FZF4", "FZF5", "FZF6", "FZF7",
  "FZF8", "FZF9", "HDSD", "HTDD", "MNPN", "MXPN", "PRCP", "PSUN", "SNOW", "TAVG",
  "TMAX", "TMIN", "TSUN", "WDF1", "WDF2", "WDF5", "WDFG", "WDFI", "WDFM", "WDMV",
  "WSF1", "WSF2", "WSF5", "WSFG", "WSFI", "WSFM"
)

input_dir <- "gsoy-latest"
output_dir <- "gsoy-merged"

if (!dir.exists(input_dir)) stop("Input directory does not exist: ", input_dir)
if (!dir.exists(output_dir)) dir.create(output_dir, showWarnings = FALSE)

file_list <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)
get_country_code <- function(filename) substr(basename(filename), 1, 2)
country_files_map <- split(file_list, sapply(file_list, get_country_code))

for (country_code in names(country_files_map)) {
  files <- country_files_map[[country_code]]
  country_data <- data.frame(matrix(ncol = length(variables), nrow = 0))
  colnames(country_data) <- variables
  cat("Processing country:", country_code, "\n")

  for (file_path in files) {
    cat("  Reading file:", file_path, "\n")
    file_data <- read.csv(file_path, stringsAsFactors = FALSE)

    filtered_data <- file_data[, intersect(colnames(file_data), variables), drop = FALSE]
    filtered_data$COUNTRY <- country_code

    for (col in setdiff(variables, colnames(filtered_data))) {
      filtered_data[[col]] <- NA
    }
    filtered_data <- filtered_data[, variables]

    country_data <- rbind(country_data, filtered_data)
  }

  output_file <- file.path(output_dir, paste0(country_code, ".csv"))
  write.csv(country_data, output_file, row.names = FALSE)
  cat("  Merged file written for:", country_code, "\n")
}

cat("Processing completed.\n")
