library(readr)

# Directories
input_dir <- "gsom-merged"
output_dir <- "gsom-aggregated"
dir.create(output_dir, showWarnings = FALSE)

# Hardcoded columns for aggregation
climate_columns <- c(
  "CDSD", "CLDD", "DP01", "DP10", "DP1X", "DT00", "DT32", "DX32", "DX70", "DX90",
  "DYNT", "DYXP", "DYXT", "EMNT", "EMXP", "EMXT", "HDSD", "HTDD", "PRCP",
  "TAVG", "TMAX", "TMIN"
)

# Function to process a file line-by-line
process_file <- function(file_path, output_path) {
  # Open file connections
  con_in <- file(file_path, "r")
  con_out <- file(output_path, "w")

  # Read the header
  header <- readLines(con_in, n = 1)
  col_names <- strsplit(header, ",")[[1]]

  # Validate required columns
  required_indices <- match(climate_columns, col_names)
  date_idx <- match("DATE", toupper(col_names))

  if (is.na(date_idx)) stop("DATE column missing in file:", file_path)
  if (any(is.na(required_indices))) stop("Missing expected climate columns in file:", file_path)

  # Prepare output header
  output_header <- paste(
    c("year_month", paste(climate_columns, c("min", "max", "avg"), sep = "_")),
    collapse = ","
  )
  writeLines(output_header, con_out)

  # Initialize variables
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

  # Process each line
  while (TRUE) {
    line <- readLines(con_in, n = 1)
    if (length(line) == 0) break # End of file

    # Parse the line
    row <- strsplit(line, ",")[[1]]
    year_month <- row[date_idx]

    # Skip malformed rows
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
      value <- as.numeric(row[match(col, col_names)])
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

  # Close file connections
  close(con_in)
  close(con_out)
}

# Process each country file
for (file in file_list) {
  country_code <- substr(basename(file), 1, 2)
  output_file <- file.path(output_dir, paste0("gsom_", country_code, ".csv"))
  cat("Processing file:", file, "\n")
  process_file(file, output_file)
  cat("Finished processing:", file, "\n")
}

cat("Aggregation completed for all files.\n")
