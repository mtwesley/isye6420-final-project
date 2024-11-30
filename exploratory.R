library(dplyr)
library(tidyr)
library(readxl)
library(ggplot2)

# get the data
emdat_data <- read_excel("public_emdat_incl_hist_2024-11-25.xlsx", sheet = "EM-DAT Data")

# review which variables are more likely to be available
emdat_vars <- lapply(emdat_data, function(var) sum(!is.na(var)) / nrow(emdat_data))

# remove variables with more than 50% missing data
emdat_available_data <- emdat_data[, emdat_vars > 0.5]

# remove non-natural disasters
emdat_available_natural_data <- emdat_data[emdat_data$`Disaster Group` == "Natural", ]

# regional coverage of natural disasters per year
emdat_available_natural_subgroups_by_region <- emdat_available_natural_data %>%

  # summarize and aggregate by regional coverage per year
  group_by(`Start Year`, `Disaster Subgroup`) %>%
  summarise(
    Observed_Regions = n_distinct(Region),
    Total_Regions = n_distinct(emdat_available_natural_data$Region),
    Coverage = Observed_Regions / Total_Regions,
    .groups = 'drop') %>%

  # pivot and fill cells
  select(`Start Year`, `Disaster Subgroup`, `Coverage`) %>%
  pivot_wider(
    names_from = `Disaster Subgroup`,
    values_from = Coverage,
    values_fill = 0)

# average coverage per region
emdat_available_natural_subgroups_by_region_summary <- emdat_available_natural_subgroups_by_region %>%
  select(-`Start Year`) %>%
  summarise(across(everything(), mean))

# sub-regional coverage of natural disasters per year
emdat_available_natural_subgroups_by_subregion <- emdat_available_natural_data %>%

  # summarize and aggregate by sub-regional coverage per year
  group_by(`Start Year`, `Disaster Subgroup`) %>%
  summarise(
    Observed_Subregions = n_distinct(Subregion),
    Total_Subregions = n_distinct(emdat_available_natural_data$Subregion),
    Coverage = Observed_Subregions / Total_Subregions,
    .groups = 'drop') %>%

  # pivot and fill cells
  select(`Start Year`, `Disaster Subgroup`, `Coverage`) %>%
  pivot_wider(
    names_from = `Disaster Subgroup`,
    values_from = Coverage,
    values_fill = 0)

# average coverage per sub-region
emdat_available_natural_subgroups_by_subregion_summary <- emdat_available_natural_subgroups_by_subregion %>%
  select(-`Start Year`) %>%
  summarise(across(everything(), mean))

# country-level coverage of natural disasters per year
emdat_available_natural_subgroups_by_country <- emdat_available_natural_data %>%

  # summarize and aggregate by country coverage per year
  group_by(`Start Year`, `Disaster Subgroup`) %>%
  summarise(
    Observed_Countries = n_distinct(Country),
    Total_Countries = n_distinct(emdat_available_natural_data$Country),
    Coverage = Observed_Countries / Total_Countries,
    .groups = "drop") %>%

  # pivot and fill cells
  select(`Start Year`, `Disaster Subgroup`, `Coverage`) %>%
  pivot_wider(
    names_from = `Disaster Subgroup`,
    values_from = Coverage,
    values_fill = 0)

# average coverage per country
emdat_available_natural_subgroups_by_country_summary <- emdat_available_natural_subgroups_by_country %>%
  select(-`Start Year`) %>%
  summarise(across(everything(), mean))

# limit to only available hydrological disaster data
emdat_hydro <- emdat_available_natural_data %>%
  filter(`Disaster Subgroup` == "Hydrological")

# review which variables are more likely to be available
emdat_hydro_vars <- lapply(emdat_hydro, function(var) sum(!is.na(var)) / nrow(emdat_hydro))

# available hydrological disaster data
emdat_hydro_data <- emdat_hydro[, emdat_hydro_vars > 0.5]

# country-level coverage of hydrological disaster types per year
emdat_hydro_types_by_country <- emdat_hydro_data %>%

  # summarize and aggregate by country coverage per year
  group_by(`Start Year`, `Disaster Type`) %>%
  summarise(
    Observed_Countries = n_distinct(Country),
    Total_Countries = n_distinct(emdat_hydro_data$Country),
    Coverage = Observed_Countries / Total_Countries,
    .groups = "drop") %>%

  # pivot and fill cells
  select(`Start Year`, `Disaster Type`, `Coverage`) %>%
  pivot_wider(
    names_from = `Disaster Type`,
    values_from = Coverage,
    values_fill = 0)

# average coverage per country
emdat_hydro_types_by_country_summary <- emdat_hydro_types_by_country %>%
  select(-`Start Year`) %>%
  summarise(across(everything(), mean))

# Filter the data for meteorological disasters
emdat_meteo_data <- emdat_available_natural_data %>%
  filter(`Disaster Subgroup` == "Meteorological")

# country-level coverage of meteorological disaster types per year
emdat_meteo_types_by_country <- emdat_meteo_data %>%

  # summarize and aggregate by country coverage per year
  group_by(`Start Year`, `Disaster Type`) %>%
  summarise(
    Observed_Countries = n_distinct(Country),
    Total_Countries = n_distinct(emdat_meteo_data$Country),
    Coverage = Observed_Countries / Total_Countries,
    .groups = "drop") %>%

  # pivot and fill cells
  select(`Start Year`, `Disaster Type`, `Coverage`) %>%
  pivot_wider(
    names_from = `Disaster Type`,
    values_from = Coverage,
    values_fill = 0)

# average coverage per country for meteorological events
emdat_meteo_types_by_country_summary <- emdat_meteo_types_by_country %>%
  select(-`Start Year`) %>%
  summarise(across(everything(), mean))

# country-level coverage of all disaster types per year
emdat_all_types_by_country <- emdat_available_natural_data %>%

  # summarize and aggregate by country coverage per year
  group_by(`Start Year`, `Disaster Type`) %>%
  summarise(
    Observed_Countries = n_distinct(Country),
    Total_Countries = n_distinct(emdat_available_natural_data$Country),
    Coverage = Observed_Countries / Total_Countries,
    .groups = "drop") %>%

  # pivot and fill cells
  select(`Start Year`, `Disaster Type`, `Coverage`) %>%
  pivot_wider(
    names_from = `Disaster Type`,
    values_from = Coverage,
    values_fill = 0)

# average coverage per country for all events, ordered by highest coverage
emdat_all_types_by_country_summary <- emdat_all_types_by_country %>%
  select(-`Start Year`) %>%
  summarise(across(everything(), mean)) %>%
  pivot_longer(
    cols = everything(),
    names_to = "Disaster Type",
    values_to = "Average Coverage"
  ) %>%
  arrange(desc(`Average Coverage`))

# floods and storms
emdat_flood_storm <- emdat_available_natural_data %>%
  filter(`Disaster Type` %in% c("Flood", "Storm"))

# Summarize flood and storm data per year
emdat_flood_storm_summary <- emdat_flood_storm %>%
  group_by(`Start Year`, `Disaster Type`) %>%
  summarise(
    Countries = n_distinct(Country),
    Disasters = n(),
    .groups = "drop") %>%
  pivot_wider(
    names_from = `Disaster Type`,
    values_from = c(Countries, Disasters),
    values_fill = 0)

# Transform the data for Flood
emdat_flood_plot <- emdat_flood_storm_summary %>%
  select(`Start Year`, Countries_Flood, Disasters_Flood) %>%
  pivot_longer(cols = -`Start Year`, names_to = "Metric", values_to = "Value")

# Line graph for Flood
ggplot(emdat_flood_plot, aes(x = `Start Year`, y = Value, color = Metric)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  labs(
    title = "Floods: Number of Countries Affected and Disasters",
    x = "Year",
    y = "Count",
    color = "Metric"
  ) +
  theme_minimal()

# Transform the data for Storm
emdat_storm_plot <- emdat_flood_storm_summary %>%
  select(`Start Year`, Countries_Storm, Disasters_Storm) %>%
  pivot_longer(cols = -`Start Year`, names_to = "Metric", values_to = "Value")

# Line graph for Storm
ggplot(emdat_storm_plot, aes(x = `Start Year`, y = Value, color = Metric)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  labs(
    title = "Storms: Number of Countries Affected and Disasters",
    x = "Year",
    y = "Count",
    color = "Metric"
  ) +
  theme_minimal()

write.csv(emdat_flood_storm_summary, "emdat_flood_storm_summary.csv", row.names = FALSE)

