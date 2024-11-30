# Load necessary libraries
library(dplyr)

# Directories
input_dir <- "gsom-merged" # Ensure this is the correct directory
output_dir <- "gsom-aggregated"
dir.create(output_dir, showWarnings = FALSE)

# Hardcoded columns for aggregation
climate_columns <- c(
  "CDSD", "CLDD", "DP01", "DP10", "DP1X", "DT00", "DT32", "DX32", "DX70", "DX90",
  "DYNT", "DYXP", "DYXT", "EMNT", "EMXP", "EMXT", "HDSD", "HTDD", "PRCP",
  "TAVG", "TMAX", "TMIN"
)

# List all CSV files in the input directory
if (!dir.exists(input_dir)) stop("Input directory does not exist: ", input_dir)
file_list <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)
if (length(file_list) == 0) stop("No .csv files found in the directory: ", input_dir)

# Function to process a file line-by-line
process_file <- function(file_path, output_path) {
  # Open file connections
  con_in <- file(file_path, "r")
  con_out <- file(output_path, "w")

  # Ensure connections are closed in case of error
  on.exit({
    if (isOpen(con_in)) close(con_in)
    if (isOpen(con_out)) close(con_out)
  })

  # Read the header line
  header <- readLines(con_in, n = 1)

  # Parse the header to get column names using read.csv
  header_df <- read.csv(text = header, header = FALSE, stringsAsFactors = FALSE)
  col_names <- as.character(header_df[1, ])

  # Validate required columns
  # required_indices <- match(climate_columns, col_names)
  date_idx <- match("DATE", toupper(col_names)) # Handle "DATE" case insensitivity

  if (is.na(date_idx)) stop("DATE column missing in file: ", file_path)

  # if (any(is.na(required_indices))) {
  #   missing_cols <- climate_columns[is.na(required_indices)]
  #   stop("Missing expected climate columns in file ", file_path, ": ", paste(missing_cols, collapse = ", "))
  # }

  # Prepare output header
  aggregated_columns <- unlist(lapply(climate_columns, function(col) {
    paste0(col, "_", c("min", "max", "avg"))
  }))
  output_header <- paste(c("year_month", aggregated_columns), collapse = ",")
  writeLines(output_header, con_out)

  # Initialize variables for aggregation
  current_month <- NULL
  running_stats <- list()

  initialize_stats <- function() {
    stats <- list()
    for (col in climate_columns) {
      stats[[col]] <- list(min = Inf, max = -Inf, sum = 0, count = 0)
    }
    return(stats)
  }

  running_stats <- initialize_stats()

  # Process each line in the file
  while (TRUE) {
    line <- readLines(con_in, n = 1)
    if (length(line) == 0) break # End of file

    # Parse the line using read.csv
    row_df <- tryCatch(
      read.csv(text = line, header = FALSE, col.names = col_names, stringsAsFactors = FALSE),
      error = function(e) {
        warning("Failed to parse line in file ", file_path, ": ", e$message)
        return(NULL)
      }
    )

    if (is.null(row_df)) next # Skip malformed lines

    # Extract year and month from the DATE column
    year_month <- row_df[[date_idx]]
    if (is.na(year_month) || !grepl("^\\d{4}-\\d{2}$", year_month)) next

    # Handle a new month
    if (!is.null(current_month) && year_month != current_month) {
      # Write aggregated stats for the current month
      result <- c(current_month)
      for (col in climate_columns) {
        stat <- running_stats[[col]]
        result <- c(
          result,
          if (stat$count > 0) stat$min else NA,
          if (stat$count > 0) stat$max else NA,
          if (stat$count > 0) stat$sum / stat$count else NA
        )
      }
      writeLines(paste(result, collapse = ","), con_out)

      # Reset stats for the next month
      running_stats <- initialize_stats()
    }

    # Update the current month
    current_month <- year_month

    # Update stats for each climate column
    for (col in climate_columns) {
      value <- as.numeric(row_df[[col]])
      if (!is.na(value)) {
        running_stats[[col]]$min <- min(running_stats[[col]]$min, value)
        running_stats[[col]]$max <- max(running_stats[[col]]$max, value)
        running_stats[[col]]$sum <- running_stats[[col]]$sum + value
        running_stats[[col]]$count <- running_stats[[col]]$count + 1
      }
    }
  }

  # Finalize the last month's data
  if (!is.null(current_month)) {
    result <- c(current_month)
    for (col in climate_columns) {
      stat <- running_stats[[col]]
      result <- c(
        result,
        if (stat$count > 0) stat$min else NA,
        if (stat$count > 0) stat$max else NA,
        if (stat$count > 0) stat$sum / stat$count else NA
      )
    }
    writeLines(paste(result, collapse = ","), con_out)
  }

  # No need to explicitly close connections here as on.exit handles it
}

# Process each CSV file in the input directory
for (file in file_list) {
  country_code <- substr(basename(file), 1, 2)
  output_file <- file.path(output_dir, paste0("gsom_", country_code, ".csv"))
  cat("Processing file:", file, "\n")
  tryCatch(
    {
      process_file(file, output_file)
      cat("Finished processing:", file, "\n")
    },
    error = function(e) {
      warning("Error processing file ", file, ": ", e$message)
    }
  )
}

cat("Aggregation completed for all files.\n")
