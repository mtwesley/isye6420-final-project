library(readr)

# Directories
input_dir <- "gsom-merged"
output_dir <- "gsom-aggregated"
dir.create(output_dir, showWarnings = FALSE)

# List all sorted country files
file_list <- list.files(input_dir, pattern = "_sorted\\.csv$", full.names = TRUE)

# Process each country file
for (file in file_list) {
  # Extract the country code from the file name
  country_code <- substr(basename(file), 1, 2)

  # Output file path
  output_file <- file.path(output_dir, paste0("gsom_", country_code, ".csv"))
  con_out <- file(output_file, "w") # Open file connection for writing

  # Write header row
  header_written <- FALSE

  # Initialize variables
  current_month <- NULL
  monthly_stats <- list() # To store running stats

  # Open file connection for reading line-by-line
  con_in <- file(file, "r")

  # Read the header row
  header <- readLines(con_in, n = 1)
  col_names <- strsplit(header, ",")[[1]]
  writeLines(header, con_out) # Write the header to the output

  # Determine column positions
  date_col_idx <- match("date", tolower(col_names))
  numeric_cols_idx <- setdiff(seq_along(col_names), c(date_col_idx)) # Assume non-date columns are numeric

  # Initialize stats for numeric columns
  initialize_month <- function() {
    stats <- list()
    for (col in col_names[numeric_cols_idx]) {
      stats[[col]] <- list(min = Inf, max = -Inf, sum = 0, count = 0)
    }
    return(stats)
  }

  # Process rows
  while (TRUE) {
    line <- readLines(con_in, n = 1)
    if (length(line) == 0) break # End of file

    # Parse row
    row <- strsplit(line, ",")[[1]]
    date <- as.Date(row[date_col_idx])
    year_month <- format(date, "%Y-%m")

    # Initialize stats for a new month
    if (!is.null(current_month) && year_month != current_month) {
      # Finalize current month's data and write to file
      result <- c(current_month)
      for (col in col_names[numeric_cols_idx]) {
        result <- c(
          result,
          monthly_stats[[col]]$min,
          monthly_stats[[col]]$max,
          monthly_stats[[col]]$sum / monthly_stats[[col]]$count
        )
      }
      writeLines(paste(result, collapse = ","), con_out)

      # Reset stats for the new month
      monthly_stats <- initialize_month()
    }

    # Update current month
    current_month <- year_month

    # Update stats for numeric columns
    for (i in numeric_cols_idx) {
      value <- as.numeric(row[i])
      if (!is.na(value)) {
        monthly_stats[[col_names[i]]]$min <- min(monthly_stats[[col_names[i]]]$min, value)
        monthly_stats[[col_names[i]]]$max <- max(monthly_stats[[col_names[i]]]$max, value)
        monthly_stats[[col_names[i]]]$sum <- monthly_stats[[col_names[i]]]$sum + value
        monthly_stats[[col_names[i]]]$count <- monthly_stats[[col_names[i]]]$count + 1
      }
    }
  }

  # Write the last month's data
  if (!is.null(current_month)) {
    result <- c(current_month)
    for (col in col_names[numeric_cols_idx]) {
      result <- c(
        result,
        monthly_stats[[col]]$min,
        monthly_stats[[col]]$max,
        monthly_stats[[col]]$sum / monthly_stats[[col]]$count
      )
    }
    writeLines(paste(result, collapse = ","), con_out)
  }

  # Close file connections
  close(con_in)
  close(con_out)

  cat("Processed and saved:", output_file, "\n")
}

# Print completion message
cat("Aggregation completed for all countries.\n")