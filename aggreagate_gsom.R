library(readr)

# Directories
input_dir <- "gsom-merged"
output_dir <- "gsom-aggregated"
dir.create(output_dir, showWarnings = FALSE)

# List all files
file_list <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)

# Function to process a file line-by-line
process_file <- function(file_path, output_path) {
  # Open file connections
  con_in <- file(file_path, "r")
  con_out <- file(output_path, "w")

  # Read the header and determine column positions
  header <- readLines(con_in, n = 1)
  col_names <- strsplit(header, ",")[[1]]
  writeLines(paste(c("year_month", paste(col_names, c("min", "max", "avg"), sep = "_")), collapse = ","), con_out)

  # Column positions
  date_idx <- match("DATE", toupper(col_names))
  numeric_indices <- setdiff(seq_along(col_names), c(date_idx))

  # Initialize variables
  current_month <- NULL
  running_stats <- list()

  initialize_stats <- function() {
    stats <- list()
    for (i in numeric_indices) {
      stats[[col_names[i]]] <- list(min = Inf, max = -Inf, sum = 0, count = 0)
    }
    return(stats)
  }

  # Process each line
  while (TRUE) {
    line <- readLines(con_in, n = 1)
    if (length(line) == 0) break # End of file

    # Parse the line
    row <- strsplit(line, ",")[[1]]
    year_month <- row[date_idx]

    # Initialize or reset stats for a new month
    if (!is.null(current_month) && year_month != current_month) {
      # Write current month's stats to the output file
      result <- c(current_month)
      for (i in numeric_indices) {
        col_name <- col_names[i]
        result <- c(
          result,
          running_stats[[col_name]]$min,
          running_stats[[col_name]]$max,
          running_stats[[col_name]]$sum / running_stats[[col_name]]$count
        )
      }
      writeLines(paste(result, collapse = ","), con_out)

      # Reset for the next month
      running_stats <- initialize_stats()
    }

    # Update the current month
    current_month <- year_month

    # Update stats for each numeric column
    for (i in numeric_indices) {
      value <- as.numeric(row[i])
      if (!is.na(value)) {
        running_stats[[col_names[i]]]$min <- min(running_stats[[col_names[i]]]$min, value)
        running_stats[[col_names[i]]]$max <- max(running_stats[[col_names[i]]]$max, value)
        running_stats[[col_names[i]]]$sum <- running_stats[[col_names[i]]]$sum + value
        running_stats[[col_names[i]]]$count <- running_stats[[col_names[i]]]$count + 1
      }
    }
  }

  # Finalize the last month's data
  if (!is.null(current_month)) {
    result <- c(current_month)
    for (i in numeric_indices) {
      col_name <- col_names[i]
      result <- c(
        result,
        running_stats[[col_name]]$min,
        running_stats[[col_name]]$max,
        running_stats[[col_name]]$sum / running_stats[[col_name]]$count
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