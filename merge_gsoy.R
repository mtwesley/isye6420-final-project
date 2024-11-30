library(dplyr)

# Define variables to include in the data
variables <- c(
  "COUNTRY", "DATE",
  "AWND",
  "CDSD", "CLDD",
  "DP01", "DP10", "DP1X", "DSND", "DSNW", "DT00", "DT32", "DX32", "DX70", "DX90", "DYFG", "DYHF", "DYTS",
  "EMNT", "EMSD", "EMSN", "EMXP", "EMXT", "EVAP",
  "FZF0", "FZF1", "FZF2", "FZF3", "FZF4", "FZF5", "FZF6", "FZF7", "FZF8", "FZF9",
  "HDSD", "HTDD",
  "MNPN", "MXPN",
  "PRCP", "PSUN",
  "SNOW",
  "TAVG", "TMAX", "TMIN", "TSUN",
  "WDF1", "WDF2", "WDF5", "WDFG", "WDFI", "WDFM", "WDMV", "WSF1", "WSF2", "WSF5", "WSFG", "WSFI", "WSFM"
)

# Directories
input_dir <- "gsoy-latest"
output_dir <- "gsoy-merged"

if (!dir.exists(input_dir)) stop("Input directory does not exist:", input_dir)
if (!dir.exists(output_dir)) dir.create(output_dir, showWarnings = FALSE)

# List all files
file_list <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)

# Extract country code from filename
get_country_code <- function(filename) substr(basename(filename), 1, 2)

# Map country codes to their respective files
country_files_map <- split(file_list, sapply(file_list, get_country_code))

# Process each country's files
for (country_code in names(country_files_map)) {
  files <- country_files_map[[country_code]]
  country_data <- data.frame(matrix(ncol = length(variables), nrow = 0))
  colnames(country_data) <- variables

  for (file_path in files) {
    # Read the CSV file
    file_data <- read.csv(file_path, stringsAsFactors = FALSE)

    # Filter and retain only relevant columns
    filtered_data <- file_data[, intersect(colnames(file_data), variables), drop = FALSE]

    # Add the COUNTRY column
    filtered_data$COUNTRY <- country_code

    # Ensure column alignment with `country_data`
    for (col in setdiff(variables, colnames(filtered_data))) {
      filtered_data[[col]] <- NA
    }
    filtered_data <- filtered_data[, variables] # Reorder columns to match

    # Append filtered data to the country's data frame
    country_data <- rbind(country_data, filtered_data)
  }

  # Write merged data for the country to a CSV file
  output_file <- file.path(output_dir, paste0(country_code, ".csv"))
  write.csv(country_data, output_file, row.names = FALSE)
  cat("Merged file written for:", country_code, "\n")
}

cat("All files processed.\n")
