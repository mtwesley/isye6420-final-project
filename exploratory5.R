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

# Step 2: Extract unique countries from each dataset
distinct_gsoy_countries <- gsoy_climate_filtered_years %>%
  select(alpha3 = ALPHA3, alpha2 = ALPHA2, m49 = M49) %>%
  distinct()

distinct_undesa_countries <- undesa_migration_filtered_years %>%
  select(alpha3, alpha2, m49) %>%
  distinct()

distinct_emdat_countries <- emdat_disaster_filtered_years %>%
  select(alpha3, alpha2, m49) %>%
  distinct()

# Step 3: Find overlapping countries across all datasets
overlapping_countries <- distinct_gsoy_countries %>%
  inner_join(distinct_undesa_countries, by = c("alpha3", "alpha2", "m49")) %>%
  inner_join(distinct_emdat_countries, by = c("alpha3", "alpha2", "m49"))

# Print overlapping countries
print(overlapping_countries)

# Step 4: Find frequency of overlapping countries across all datasets
freq_gsoy_countries <- gsoy_climate_filtered_years %>%
  select(alpha3 = ALPHA3, alpha2 = ALPHA2, m49 = M49) %>%
  filter(alpha3 %in% overlapping_countries$alpha3) %>%
  mutate(dataset = "GSOY")

freq_undesa_countries <- undesa_migration_filtered_years %>%
  select(alpha3, alpha2, m49) %>%
  filter(alpha3 %in% overlapping_countries$alpha3) %>%
  mutate(dataset = "UNDESA")

freq_emdat_countries <- emdat_disaster_filtered_years %>%
  select(alpha3, alpha2, m49) %>%
  filter(alpha3 %in% overlapping_countries$alpha3) %>%
  mutate(dataset = "EMDAT")

# Combine all countries into one dataset
freq_all_countries <- bind_rows(freq_gsoy_countries, freq_undesa_countries, freq_emdat_countries)

# Count occurrences of each country
freq_country_frequency <- freq_all_countries %>%
  group_by(alpha3, alpha2, m49) %>%
  summarise(count = n(), .groups = "drop") %>%
  arrange(desc(count))

# Save or print the resulting dataset
print(freq_country_frequency)

# Step 5: Visualization
ggplot(freq_country_frequency, aes(x = reorder(alpha3, -count), y = count)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(
    title = "Frequency of Overlapping Countries Across Datasets (1980–2020)",
    x = "Country (Alpha-3 Code)",
    y = "Frequency"
  ) +
  theme_minimal() +
  coord_flip()
