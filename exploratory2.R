# Libraries
library(dplyr)
library(ggplot2)

# Extract unique years and count occurrences for UNDESA
undesa_years <- sort(unique(as.numeric(undesa_data_migration$year)))
undesa_counts <- undesa_data_migration %>%
  group_by(year = as.numeric(year)) %>%
  summarise(migrant_records = n(), .groups = "drop")

# UNDESA interval: only earliest and latest years are critical
undesa_interval <- data.frame(start = min(undesa_years), end = max(undesa_years))

# Extract unique years for GSOY and EMDAT
gsoy_years <- sort(unique(gsoy_climate$YEAR))
emdat_years <- sort(unique(emdat_flood_storm_aggregated$year))

# Function to group years into intervals
group_years_to_intervals <- function(years) {
  if (length(years) == 0) return(data.frame(start = integer(), end = integer()))
  breaks <- c(1, which(diff(years) > 1) + 1, length(years) + 1)
  intervals <- data.frame(
    start = years[breaks[-length(breaks)]],
    end = years[breaks[-1] - 1]
  )
  return(intervals)
}

# Group years into intervals for GSOY and EMDAT
gsoy_intervals <- group_years_to_intervals(gsoy_years)
emdat_intervals <- group_years_to_intervals(emdat_years)

# Combine intervals into a single dataframe for visualization
intervals_df <- bind_rows(
  mutate(gsoy_intervals, dataset = "GSOY Climate"),
  mutate(emdat_intervals, dataset = "EMDAT Flood/Storm"),
  mutate(undesa_interval, dataset = "UNDESA Migration")
)

# Visualization of intervals
ggplot(intervals_df, aes(x = start, xend = end, y = dataset, yend = dataset, color = dataset)) +
  geom_segment(size = 3) +
  theme_minimal() +
  labs(
    title = "Year Intervals for Datasets",
    x = "Year",
    y = "Dataset",
    color = "Dataset"
  )

# Overlapping intervals (adjusted for UNDESA coverage based on earliest and latest year)
all_years <- unique(c(gsoy_years, emdat_years, undesa_years))
overlapping_years <- all_years[all_years %in% gsoy_years & all_years %in% emdat_years & all_years >= min(undesa_years) & all_years <= max(undesa_years)]
overlapping_intervals <- group_years_to_intervals(overlapping_years)

# Visualization of overlapping intervals
ggplot(overlapping_intervals, aes(x = start, xend = end, y = "Overlap", yend = "Overlap")) +
  geom_segment(size = 3, color = "blue") +
  theme_minimal() +
  labs(
    title = "Overlapping Year Intervals Across All Datasets",
    x = "Year",
    y = "",
    color = ""
  )

# Amount of data available for each year in all datasets
data_availability <- data.frame(
  year = all_years,
  GSOY = as.integer(all_years %in% gsoy_years),
  EMDAT = as.integer(all_years %in% emdat_years),
  UNDESA = ifelse(all_years %in% undesa_years, undesa_counts$migrant_records[match(all_years, undesa_years)], 0)
)

# Visualization of data availability per year
data_availability_long <- data_availability %>%
  pivot_longer(cols = -year, names_to = "Dataset", values_to = "Available")

ggplot(data_availability_long, aes(x = year, y = Available, fill = Dataset)) +
  geom_bar(stat = "identity", position = "stack") +
  theme_minimal() +
  labs(
    title = "Data Availability Across Datasets by Year",
    x = "Year",
    y = "Records Available",
    fill = "Dataset"
  )

