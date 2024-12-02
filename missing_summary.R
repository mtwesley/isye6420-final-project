library(dplyr)

# Define the climate variables
climate_variables <- c("prcp_mean", "emxp_max", "emnt_min", "emxt_max", "tmax_max", "tmin_min", "tavg_mean")

# Create all possible subsets of the climate variables
all_combinations <- unlist(lapply(0:length(climate_variables), function(k) {
  combn(climate_variables, k, simplify = FALSE)
}), recursive = FALSE)

# Reverse the order to start with the largest subsets
all_combinations <- rev(all_combinations)

# Initialize the list for storing partitions
disaster_determinants_partitioned_subsets <- list()

# Create a copy of the original data to track remainder rows
remainder_rows <- disaster_determinants_80_countries

# Iterate through each combination of variables
for (combo in all_combinations) {
  if (length(combo) == 0) next  # Skip the empty combination

  # Filter rows where all variables in the current combination are not NA
  matching_rows <- remainder_rows %>%
    filter(if_all(all_of(combo), ~ !is.na(.))) %>%
    select(all_of(combo), everything())  # Retain the current variables and others for context

  # If there are matching rows, add them to the partition and remove from remainder
  if (nrow(matching_rows) > 0) {
    disaster_determinants_partitioned_subsets[[paste(combo, collapse = ", ")]] <- matching_rows
    remainder_rows <- anti_join(remainder_rows, matching_rows, by = names(remainder_rows))
  }
}

# Include the final remainder rows as a separate subset if any rows are left
if (nrow(remainder_rows) > 0) {
  disaster_determinants_partitioned_subsets[["Remainder"]] <- remainder_rows
}













# Define the climate variables
climate_variables <- c("prcp_mean", "emxp_max", "emnt_min", "emxt_max", "tmax_max", "tmin_min", "tavg_mean")

# Initialize a data frame to store results
na_summary_table <- data.frame()

# Iterate over each subset and check for NA values in the climate variables
for (i in seq_along(disaster_determinants_partitioned_subsets)) {
  subset <- disaster_determinants_partitioned_subsets[[i]]

  # Check NA status for climate variables in the current subset
  na_check <- sapply(climate_variables, function(var) {
    if (var %in% colnames(subset)) {
      any(is.na(subset[[var]]))
    } else {
      NA  # If the variable is not present in the subset
    }
  })

  # Add the results as a row in the summary table
  na_summary_table <- rbind(na_summary_table, cbind(Subset = paste0("Subset_", i), t(na_check)))
}

# Rename columns for better readability
colnames(na_summary_table) <- c("Subset", climate_variables)
