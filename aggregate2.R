process_climate_data_folder <- function(input_folder, output_folder, chunk_size = 1) {
  # Ensure the output folder exists
  if (!dir.exists(output_folder)) {
    dir.create(output_folder)
    cat("Created output folder:", output_folder, "\n")
  }

  # Get the list of CSV files in the input folder
  file_list <- list.files(input_folder, pattern = "\\.csv$", full.names = TRUE)

  if (length(file_list) == 0) {
    stop("No CSV files found in the input folder.")
  }

  # Process each file
  for (file_path in file_list) {
    # Extract the two-letter country prefix from the file name
    country_code <- gsub("\\.csv$", "", basename(file_path))

    cat("Processing file:", file_path, "for country:", country_code, "\n")

    # Generate the output file path
    output_file <- file.path(output_folder, paste0(country_code, "_aggregated.csv"))

    # Initialize an empty list to store aggregated data
    aggregated_data <- list()

    # Open a connection to the input file
    con <- file(file_path, "r")

    # Read the header to get column names
    header_line <- readLines(con, n = 1)
    col_names <- strsplit(header_line, ",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)", perl = TRUE)[[1]]
    num_cols <- length(col_names)

    # Function to parse rows and truncate to the correct number of columns
    parse_and_truncate_row <- function(line, col_names) {
      fields <- strsplit(line, ",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)", perl = TRUE)[[1]]
      # Truncate or pad the row to match the header's column count
      if (length(fields) > num_cols) {
        fields <- fields[1:num_cols]
      } else if (length(fields) < num_cols) {
        fields <- c(fields, rep(NA, num_cols - length(fields)))
      }
      setNames(fields, col_names)
    }

    # Read and process rows one by one
    repeat {
      line <- readLines(con, n = 1)

      # Break if end of file is reached
      if (length(line) == 0) break

      # Parse the row and truncate columns if necessary
      row <- tryCatch(
        as.data.frame(t(parse_and_truncate_row(line, col_names)), stringsAsFactors = FALSE),
        error = function(e) {
          cat("Error parsing row from", file_path, ":", e$message, "\n")
          NULL
        }
      )

      if (is.null(row) || nrow(row) == 0) next

      # Use DATE as a plain text column
      date <- as.character(row$DATE)

      # Skip rows with missing DATE
      if (is.na(date) || date == "") {
        cat("Skipping row with missing DATE:", line, "\n")
        next
      }

      # Add the COUNTRY column
      row$COUNTRY <- country_code

      # Initialize the date in the aggregated_data if not already present
      if (!date %in% names(aggregated_data)) {
        aggregated_data[[date]] <- list(COUNTRY = country_code)
        for (var in setdiff(col_names, c("STATION", "LATITUDE", "LONGITUDE", "ELEVATION", "NAME", "DATE"))) {
          aggregated_data[[date]][[var]] <- list(
            min = Inf, max = -Inf, total = 0, count = 0
          )
        }
      }

      # Update aggregated data for each climate variable
      for (var in setdiff(col_names, c("STATION", "LATITUDE", "LONGITUDE", "ELEVATION", "NAME", "DATE"))) {
        value <- suppressWarnings(as.numeric(row[[var]]))

        if (!is.na(value)) {
          aggregated_data[[date]][[var]]$min <- min(aggregated_data[[date]][[var]]$min, value, na.rm = TRUE)
          aggregated_data[[date]][[var]]$max <- max(aggregated_data[[date]][[var]]$max, value, na.rm = TRUE)
          aggregated_data[[date]][[var]]$total <- aggregated_data[[date]][[var]]$total + value
          aggregated_data[[date]][[var]]$count <- aggregated_data[[date]][[var]]$count + 1
        }
      }
    }

    # Close the connection to the input file
    close(con)

    # Handle empty aggregated_data gracefully
    if (length(aggregated_data) == 0) {
      cat("No valid rows found in", file_path, ". Skipping file.\n")
      next
    }

    # Convert aggregated_data to a data frame
    result <- data.frame(DATE = names(aggregated_data), COUNTRY = country_code, stringsAsFactors = FALSE)

    # For each climate variable, extract min, max, total, count, and compute avg
    for (var in setdiff(col_names, c("STATION", "LATITUDE", "LONGITUDE", "ELEVATION", "NAME", "DATE"))) {
      min_values <- vapply(aggregated_data, function(x) x[[var]]$min, numeric(1))
      min_values[min_values == Inf] <- NA
      result[[paste0(var, "_min")]] <- min_values

      max_values <- vapply(aggregated_data, function(x) x[[var]]$max, numeric(1))
      max_values[max_values == -Inf] <- NA
      result[[paste0(var, "_max")]] <- max_values

      total_values <- vapply(aggregated_data, function(x) x[[var]]$total, numeric(1))
      result[[paste0(var, "_total")]] <- total_values

      count_values <- vapply(aggregated_data, function(x) x[[var]]$count, numeric(1))
      result[[paste0(var, "_count")]] <- count_values

      result[[paste0(var, "_avg")]] <- ifelse(
        result[[paste0(var, "_count")]] > 0,
        result[[paste0(var, "_total")]] / result[[paste0(var, "_count")]],
        NA
      )
    }

    result <- result[order(result$DATE), ]

    write.csv(result, output_file, row.names = FALSE)
    cat("Aggregated data for", country_code, "has been written to", output_file, "\n\n")
  }

  cat("All files have been processed.\n")
}

# Example usage
# Ensure that the "gsom-merged" and "gsom-aggregated" folders exist in the working directory
process_climate_data_folder("gsom-merged", "gsom-aggregated")
