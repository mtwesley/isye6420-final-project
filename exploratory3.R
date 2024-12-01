library(dplyr)
library(ggplot2)

# Step 1: Filter datasets by years of interest
year_range <- 1980:2020

gsoy_climate_filtered_years <- gsoy_climate_final %>%
  filter(YEAR %in% year_range)

undesa_migration_filtered_years <- undesa_migration_final %>%
  filter(as.numeric(year) %in% year_range)

emdat_disaster_filtered_years <- emdat_diaster_final %>%
  filter(year %in% year_range)

# Step 2: Harmonize datasets to use alpha3 for country codes and rename year columns
gsoy_countries <- gsoy_climate_filtered_years %>%
  select(year = YEAR, country = ALPHA3)

undesa_countries <- undesa_migration_filtered_years %>%
  mutate(year = as.numeric(year)) %>% # Ensure year is numeric
  select(year, country = alpha3)

emdat_countries <- emdat_disaster_filtered_years %>%
  select(year, country = alpha3)

# Step 3: Compute overlap of countries by year
overlapping_countries_by_year <- gsoy_countries %>%
  inner_join(undesa_countries, by = c("year", "country")) %>%
  inner_join(emdat_countries, by = c("year", "country")) %>%
  group_by(year) %>%
  summarise(overlapping_countries = n_distinct(country), .groups = "drop") %>%
  mutate(dataset = "Overlap")

# Step 4: Calculate individual dataset country coverage
gsoy_countries_by_year <- gsoy_countries %>%
  group_by(year) %>%
  summarise(countries = n_distinct(country), .groups = "drop") %>%
  mutate(dataset = "GSOY")

undesa_countries_by_year <- undesa_countries %>%
  group_by(year) %>%
  summarise(countries = n_distinct(country), .groups = "drop") %>%
  mutate(dataset = "UNDESA")

emdat_countries_by_year <- emdat_countries %>%
  group_by(year) %>%
  summarise(countries = n_distinct(country), .groups = "drop") %>%
  mutate(dataset = "EMDAT")

# Step 5: Combine all datasets for comparison
combined_country_coverage <- bind_rows(
  gsoy_countries_by_year,
  undesa_countries_by_year,
  emdat_countries_by_year,
  overlapping_countries_by_year %>% rename(countries = overlapping_countries)
)

# Step 6: Tabular Output
coverage_summary_table <- combined_country_coverage %>%
  group_by(dataset) %>%
  summarise(
    min_year = min(year, na.rm = TRUE),
    max_year = max(year, na.rm = TRUE),
    avg_countries = mean(countries, na.rm = TRUE),
    total_countries = sum(countries, na.rm = TRUE),
    .groups = "drop"
  )

# Print coverage summary table
print(coverage_summary_table)

# Step 7: Visualization
# Line plot for country coverage over years
ggplot(combined_country_coverage, aes(x = year, y = countries, color = dataset)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  labs(
    title = "Country Coverage by Dataset and Overlap (1980–2020)",
    x = "Year",
    y = "Number of Countries Represented",
    color = "Dataset"
  ) +
  theme_minimal()

# Step 1: Extract unique countries from each dataset
distinct_gsoy_countries <- gsoy_climate_filtered_years %>%
  select(alpha3 = ALPHA3, alpha2 = ALPHA2, m49 = M49) %>%
  distinct()

distinct_undesa_countries <- undesa_migration_filtered_years %>%
  select(alpha3, alpha2, m49) %>%
  distinct()

distinct_emdat_countries <- emdat_disaster_filtered_years %>%
  select(alpha3, alpha2, m49) %>%
  distinct()

# Step 2: Find overlapping countries across all datasets
overlapping_countries <- distinct_gsoy_countries %>%
  inner_join(distinct_undesa_countries, by = c("alpha3", "alpha2", "m49")) %>%
  inner_join(distinct_emdat_countries, by = c("alpha3", "alpha2", "m49"))

# Step 3: Save or print the resulting dataset
print(overlapping_countries)

freq_gsoy_countries <- gsoy_climate_filtered_years %>%
  select(alpha3 = ALPHA3, alpha2 = ALPHA2, m49 = M49) %>%
  mutate(dataset = "GSOY")

freq_undesa_countries <- undesa_migration_filtered_years %>%
  select(alpha3, alpha2, m49) %>%
  mutate(dataset = "UNDESA")

freq_emdat_countries <- emdat_disaster_filtered_years %>%
  select(alpha3, alpha2, m49) %>%
  mutate(dataset = "EMDAT")

# Combine all countries into one dataset
freq_all_countries <- bind_rows(freq_gsoy_countries, freq_undesa_countries, freq_emdat_countries)

# Step 2: Count occurrences of each country
freq_country_frequency <- freq_all_countries %>%
  group_by(alpha3, alpha2, m49) %>%
  summarise(count = n(), .groups = "drop") %>%
  arrange(desc(count))

# Step 3: Save or print the resulting dataset
print(freq_country_frequency)

