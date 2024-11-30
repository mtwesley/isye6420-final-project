# Load necessary libraries
library(dplyr)

# Function to process climate data with COUNTRY column
process_climate_data_folder <- function(input_folder, output_folder, chunk_size = 1000) {
  # Ensure the output folder exists
  if (!dir.exists(output_folder)) {
    dir.create(output_folder)
  }

  # Get the list of CSV files in the input folder
  file_list <- list.files(input_folder, pattern = "\\.csv$", full.names = TRUE)

  # Process each file
  for (file_path in file_list) {
    # Extract the two-letter country prefix from the file name
    country_code <- gsub("\\.csv$", "", basename(file_path))

    # Generate the output file path
    output_file <- file.path(output_folder, paste0(country_code, "_aggregated.csv"))

    # Initialize an empty list to store aggregated data
    aggregated_data <- list()

    # Open a connection to the input file
    con <- file(file_path, "r")

    # Read the header to get column names
    header <- read.csv(con, nrows = 1, stringsAsFactors = FALSE)
    col_names <- colnames(header)

    # Identify metadata columns and climate variables
    metadata_cols <- c("STATION", "LATITUDE", "LONGITUDE", "ELEVATION", "NAME")
    climate_vars <- setdiff(col_names, c(metadata_cols, "DATE", paste0(col_names, "_ATTRIBUTES")))

    # Process the file in chunks
    repeat {
      # Read a chunk of data
      chunk <- tryCatch(read.csv(con, nrows = chunk_size, stringsAsFactors = FALSE, col.names = col_names), error = function(e) NULL)
      if (is.null(chunk) || nrow(chunk) == 0) break

      # Convert the DATE column to Date format
      chunk$DATE <- as.Date(chunk$DATE, format = "%Y-%m")

      # Add the COUNTRY column
      chunk$COUNTRY <- country_code

      # Process each row in the chunk
      for (i in 1:nrow(chunk)) {
        row <- chunk[i, ]
        date <- as.character(row$DATE)

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
          value <- as.numeric(row[[var]])
          if (!is.na(value)) {
            aggregated_data[[date]][[var]]$min <- min(aggregated_data[[date]][[var]]$min, value)
            aggregated_data[[date]][[var]]$max <- max(aggregated_data[[date]][[var]]$max, value)
            aggregated_data[[date]][[var]]$total <- aggregated_data[[date]][[var]]$total + value
            aggregated_data[[date]][[var]]$count <- aggregated_data[[date]][[var]]$count + 1
          }
        }
      }
    }

    # Close the connection to the input file
    close(con)

    # Convert aggregated_data to a data frame
    result <- data.frame(DATE = names(aggregated_data), COUNTRY = country_code)

    for (var in climate_vars) {
      result[[paste0(var, "_min")]] <- sapply(aggregated_data, function(x) x[[var]]$min)
      result[[paste0(var, "_max")]] <- sapply(aggregated_data, function(x) x[[var]]$max)
      result[[paste0(var, "_total")]] <- sapply(aggregated_data, function(x) x[[var]]$total)
      result[[paste0(var, "_count")]] <- sapply(aggregated_data, function(x) x[[var]]$count)
      result[[paste0(var, "_avg")]] <- result[[paste0(var, "_total")]] / result[[paste0(var, "_count")]]
    }

    # Write the aggregated data to the output file
    write.csv(result, output_file, row.names = FALSE)
    cat("Aggregated data for", country_code, "has been written to", output_file, "\n")
  }
}

# Example usage
# Replace "gsom-merged" and "gsom-aggregated" with the actual folder paths
process_climate_data_folder("gsom-merged", "gsom-aggregated")
