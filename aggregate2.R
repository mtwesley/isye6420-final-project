# Load necessary libraries
library(dplyr)

# Function to process climate data with COUNTRY column
process_climate_data_folder <- function(input_folder, output_folder, chunk_size = 1000) {
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
    header <- tryCatch(
      read.csv(con, nrows = 1, stringsAsFactors = FALSE),
      error = function(e) {
        close(con)
        stop("Failed to read header from ", file_path, ": ", e$message)
      }
    )
    col_names <- colnames(header)

    # Identify metadata columns and climate variables
    metadata_cols <- c("STATION", "LATITUDE", "LONGITUDE", "ELEVATION", "NAME")
    # Exclude columns with "_ATTRIBUTES" suffix
    attributes_cols <- grep("_ATTRIBUTES$", col_names, value = TRUE)
    climate_vars <- setdiff(col_names, c(metadata_cols, "DATE", attributes_cols))

    if (length(climate_vars) == 0) {
      close(con)
      cat("No climate variables found in", file_path, ". Skipping file.\n")
      next
    }

    # Process the file in chunks
    repeat {
      # Read a chunk of data
      chunk <- tryCatch(
        read.csv(con, nrows = chunk_size, stringsAsFactors = FALSE, col.names = col_names),
        error = function(e) {
          cat("Error reading chunk from", file_path, ":", e$message, "\n")
          NULL
        }
      )

      if (is.null(chunk) || nrow(chunk) == 0) break

      # Convert the DATE column to Date format
      # Assuming DATE is in "YYYY-MM" format; adjust if necessary
      chunk$DATE <- as.Date(paste0(chunk$DATE, "-01"), format = "%Y-%m-%d")

      # Add the COUNTRY column
      chunk$COUNTRY <- country_code

      # Process each row in the chunk
      for (i in 1:nrow(chunk)) {
        row <- chunk[i, ]
        date <- as.character(row$DATE)

        # Skip rows with invalid DATE
        if (is.na(date)) {
          next
        }

        # Initialize the date in the aggregated_data if not already present
        if (!date %in% names(aggregated_data)) {
          aggregated_data[[date]] <- list(COUNTRY = country_code)
          for (var in climate_vars) {
            aggregated_data[[date]][[var]] <- list(
              min = Inf, max = -Inf, total = 0, count = 0
            )
          }
        }

        # Update aggregated data for each climate variable
        for (var in climate_vars) {
          # Attempt to convert the value to numeric, suppress warnings for non-numeric entries
          value <- suppressWarnings(as.numeric(row[[var]]))

          if (!is.na(value)) {
            aggregated_data[[date]][[var]]$min <- min(aggregated_data[[date]][[var]]$min, value, na.rm = TRUE)
            aggregated_data[[date]][[var]]$max <- max(aggregated_data[[date]][[var]]$max, value, na.rm = TRUE)
            aggregated_data[[date]][[var]]$total <- aggregated_data[[date]][[var]]$total + value
            aggregated_data[[date]][[var]]$count <- aggregated_data[[date]][[var]]$count + 1
          }
        }
      }
    }

    # Close the connection to the input file
    close(con)

    # Convert aggregated_data to a data frame
    # Initialize the result data frame with DATE and COUNTRY
    result <- data.frame(DATE = names(aggregated_data), COUNTRY = country_code, stringsAsFactors = FALSE)

    # For each climate variable, extract min, max, total, count and compute avg
    for (var in climate_vars) {
      # Extract min
      min_values <- vapply(aggregated_data, function(x) x[[var]]$min, numeric(1))
      # Replace Inf with NA (no valid data for this variable and date)
      min_values[min_values == Inf] <- NA
      result[[paste0(var, "_min")]] <- min_values

      # Extract max
      max_values <- vapply(aggregated_data, function(x) x[[var]]$max, numeric(1))
      # Replace -Inf with NA (no valid data for this variable and date)
      max_values[max_values == -Inf] <- NA
      result[[paste0(var, "_max")]] <- max_values

      # Extract total
      total_values <- vapply(aggregated_data, function(x) x[[var]]$total, numeric(1))
      # Ensure total is numeric
      result[[paste0(var, "_total")]] <- total_values

      # Extract count
      count_values <- vapply(aggregated_data, function(x) x[[var]]$count, numeric(1))
      # Ensure count is numeric
      result[[paste0(var, "_count")]] <- count_values

      # Compute average, avoiding division by zero and handling NAs
      result[[paste0(var, "_avg")]] <- ifelse(
        result[[paste0(var, "_count")]] > 0,
        result[[paste0(var, "_total")]] / result[[paste0(var, "_count")]],
        NA
      )
    }

    # Optional: Arrange the columns in a logical order
    # For example: DATE, COUNTRY, var1_min, var1_max, var1_total, var1_count, var1_avg, var2_min, ...
    # Here, we'll just arrange by DATE
    result <- result %>% arrange(DATE)

    # Write the aggregated data to the output file
    write.csv(result, output_file, row.names = FALSE)
    cat("Aggregated data for", country_code, "has been written to", output_file, "\n\n")
  }

  cat("All files have been processed.\n")
}

# Example usage
# Ensure that the "gsom-merged" and "gsom-aggregated" folders exist in the working directory
process_climate_data_folder("gsom-merged", "gsom-aggregated")
