# Load necessary libraries
library(dplyr)

# Function to process climate data with COUNTRY column, reading line-by-line
process_climate_data_folder <- function(input_folder, output_folder) {
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

    # Open the connection to the input file
    con <- file(file_path, "r")

    # Read the header line
    header_line <- readLines(con, n = 1)
    if (length(header_line) == 0) {
      close(con)
      cat("Empty file:", file_path, ". Skipping.\n")
      next
    }

    # Parse the header
    header <- tryCatch(
      read.csv(text = header_line, header = TRUE, stringsAsFactors = FALSE),
      error = function(e) {
        close(con)
        cat("Failed to parse header in", file_path, ": ", e$message, "\n")
        return(NULL)
      }
    )

    if (is.null(header)) {
      next
    }

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

    # Read and process each line
    line_num <- 1
    while (length(line <- readLines(con, n = 1)) > 0) {
      line_num <- line_num + 1
      # Skip empty lines
      if (nchar(trimws(line)) == 0) {
        next
      }

      # Parse the line
      row_data <- tryCatch(
        read.csv(text = line, header = FALSE, stringsAsFactors = FALSE),
        error = function(e) {
          cat("Failed to parse line", line_num, "in", file_path, ":", e$message, "\n")
          return(NULL)
        }
      )

      if (is.null(row_data)) {
        next
      }

      # Check if number of columns matches
      if (ncol(row_data) != length(col_names)) {
        cat("Line", line_num, "in", file_path, "has", ncol(row_data), "columns, expected", length(col_names), ". Skipping line.\n")
        next
      }

      # Assign column names
      colnames(row_data) <- col_names

      # Extract DATE as text
      date_str <- row_data$DATE
      date_char <- as.character(date_str)

      # Initialize the date in aggregated_data if not already present
      if (!date_char %in% names(aggregated_data)) {
        aggregated_data[[date_char]] <- list(COUNTRY = country_code)
        for (var in climate_vars) {
          aggregated_data[[date_char]][[var]] <- list(
            min = Inf,
            max = -Inf,
            total = 0,
            count = 0
          )
        }
      }

      # Update aggregated data for each climate variable
      for (var in climate_vars) {
        value <- suppressWarnings(as.numeric(row_data[[var]]))
        if (!is.na(value)) {
          aggregated_data[[date_char]][[var]]$min <- min(aggregated_data[[date_char]][[var]]$min, value, na.rm = TRUE)
          aggregated_data[[date_char]][[var]]$max <- max(aggregated_data[[date_char]][[var]]$max, value, na.rm = TRUE)
          aggregated_data[[date_char]][[var]]$total <- aggregated_data[[date_char]][[var]]$total + value
          aggregated_data[[date_char]][[var]]$count <- aggregated_data[[date_char]][[var]]$count + 1
        }
      }
    }

    # Close the connection
    close(con)

    # Convert aggregated_data to data.frame
    if (length(aggregated_data) == 0) {
      cat("No valid data aggregated for", country_code, ". Skipping file.\n")
      next
    }

    result <- data.frame(DATE = names(aggregated_data), COUNTRY = country_code, stringsAsFactors = FALSE)

    for (var in climate_vars) {
      # Extract min
      min_values <- vapply(aggregated_data, function(x) x[[var]]$min, numeric(1))
      # Replace Inf with NA
      min_values[min_values == Inf] <- NA
      result[[paste0(var, "_min")]] <- min_values

      # Extract max
      max_values <- vapply(aggregated_data, function(x) x[[var]]$max, numeric(1))
      # Replace -Inf with NA
      max_values[max_values == -Inf] <- NA
      result[[paste0(var, "_max")]] <- max_values

      # Extract total
      total_values <- vapply(aggregated_data, function(x) x[[var]]$total, numeric(1))
      result[[paste0(var, "_total")]] <- total_values

      # Extract count
      count_values <- vapply(aggregated_data, function(x) x[[var]]$count, numeric(1))
      result[[paste0(var, "_count")]] <- count_values

      # Compute avg
      result[[paste0(var, "_avg")]] <- ifelse(
        result[[paste0(var, "_count")]] > 0,
        result[[paste0(var, "_total")]] / result[[paste0(var, "_count")]],
        NA
      )
    }

    # Arrange by DATE (treated as text)
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
