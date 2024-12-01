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

# write.csv(emdat_flood_storm_summary, "emdat_flood_storm_summary.csv", row.names = FALSE)

emdat_flood_storm_data <- emdat_flood_storm %>%
  select(
    year = `Start Year`,
    alpha3 = ISO,
    country = Country,
    region = Subregion,
    subregion = Region,
    disaster = `Disaster Type`,
    deaths = `Total Deaths`,
    livesAffected = `Total Affected`,
    economicDamage = `Total Damage, Adjusted ('000 US$)`
  )

emdat_flood_storm_aggregated <- emdat_flood_storm_data %>%
  group_by(year, alpha3, country, region, subregion) %>%
  summarise(
    storms = sum(disaster == "Storm", na.rm = TRUE),
    floods = sum(disaster == "Flood", na.rm = TRUE),
    deaths = sum(deaths, na.rm = TRUE),
    livesAffected = sum(livesAffected, na.rm = TRUE),
    economicDamage = sum(economicDamage, na.rm = TRUE),
    .groups = "drop"
  )

# UNDESA migration data
undesa_data <- read_excel("undesa/undesa_pd_2020_ims_stock_origin_world.xlsx", skip = 3)

undesa_data <- undesa_data %>%
  rename(
    country = `Region, development group, country or area of origin`,
    m49 = `Location code of origin`
  ) %>%
  mutate(m49 = sprintf("%03d", as.numeric(m49)))

undesa_data_migration <- undesa_data %>%
  pivot_longer(
    cols = -c(country, m49),
    names_to = "year",
    values_to = "migrants"
  ) %>%
  group_by(country, m49, year) %>%
  summarise(migrants = sum(migrants, na.rm = TRUE), .groups = "drop")


prefix_to_country_code <- data.frame(
  prefix = c("AJ", "AY", "BC", "BK", "BP", "BU", "CE", "CJ", "CQ", "CS", "CT", "DA", "DR", "EI", "EN", "EU", "EZ",
             "FG", "FP", "FS", "HO", "IC", "IV", "JA", "JN", "JQ", "JU", "KS", "KT", "KU", "LE", "LG", "LH", "LO",
             "MB", "MI", "MJ", "NH", "NN", "NS", "PC", "PO", "PP", "RI", "RM", "RP", "RQ", "SF", "SP", "SU", "SW",
             "TE", "TI", "TS", "TU", "TX", "UC", "UK", "UP", "UV", "VM", "VQ", "WA", "WI", "WQ", "WZ", "ZI"),
  country = c("AZ", "AQ", "BW", "BA", "SB", "BG", "LK", "KY", "MP", "CR", "CF", "DK", "DO", "IE", "EE", "FR", "CZ",
              "FR", "FR", "FR", "HN", "IS", "CI", "JP", "NO", "US", "FR", "KR", "AU", "KW", "LB", "EE", "LT", "SK",
              "FR", "MW", "ME", "VU", "NL", "SR", "PN", "PT", "PG", "RS", "MH", "PH", "US", "ZA", "ES", "SD", "SE",
              "FR", "UZ", "TN", "TR", "TM", "NL", "GB", "UA", "BF", "VN", "US", "NA", "MA", "US", "SZ", "ZW")
)

# GSOY climate data
gsoy_data <- read_csv("gsoy-aggregated-fixed.csv")

gsoy_climate <- gsoy_data %>%
  rename(YEAR = DATE, ALPHA2 = COUNTRY)

prefix_to_country_code <- data.frame(
  prefix = c("AJ", "AY", "BC", "BK", "BP", "BU", "CE", "CJ", "CQ", "CS", "CT", "DA", "DR", "EI", "EN", "EU", "EZ",
             "FG", "FP", "FS", "HO", "IC", "IV", "JA", "JN", "JQ", "JU", "KS", "KT", "KU", "LE", "LG", "LH", "LO",
             "MB", "MI", "MJ", "NH", "NN", "NS", "PC", "PO", "PP", "RI", "RM", "RP", "RQ", "SF", "SP", "SU", "SW",
             "TE", "TI", "TS", "TU", "TX", "UC", "UK", "UP", "UV", "VM", "VQ", "WA", "WI", "WQ", "WZ", "ZI"),

  new_code = c("AZ", "AQ", "BW", "BA", "SB", "BG", "LK", "KY", "MP", "CR", "CF", "DK", "DO", "IE", "EE", "FR", "CZ",
               "FR", "FR", "FR", "HN", "IS", "CI", "JP", "NO", "US", "FR", "KR", "AU", "KW", "LB", "EE", "LT", "SK",
               "FR", "MW", "ME", "VU", "NL", "SR", "PN", "PT", "PG", "RS", "MH", "PH", "US", "ZA", "ES", "SD", "SE",
               "FR", "UZ", "TN", "TR", "TM", "NL", "GB", "UA", "BF", "VN", "US", "NA", "MA", "US", "SZ", "ZW")
)

# Apply the mappings
gsoy_climate <- gsoy_climate %>%
  left_join(prefix_to_country_code, by = c("ALPHA2" = "prefix"), relationship = "many-to-many") %>%
  mutate(ALPHA2 = coalesce(new_code, ALPHA2)) %>%
  select(-new_code) %>%
  rename_with(toupper)

# gsoy_climate_final <- gsoy_data %>%
#   rename(ALPHA2 = COUNTRY) %>%
#   left_join(prefix_to_country_code, by = c("ALPHA2" = "prefix")) %>%
#   mutate(
#     ALPHA2 = ifelse(!is.na(country), country, ALPHA2)
#   ) %>%
#   select(-country)

# gsoy_climate <- gsoy_data %>%
#   rename(
#     YEAR = DATE,
#     ALPHA2 = COUNTRY
#   )

# GSOY has old coding that does not comply with ISO2 letter encoding
# prefix_country_lookup <- read.csv("prefix_country_lookup.csv") %>%
#   mutate(country = toupper(country))

# gsoy_climate <- gsoy_climate %>%
#   mutate(
#     COUNTRY = ifelse(
#       ALPHA2 %in% prefix_country_lookup$prefix,
#       prefix_country_lookup$country[match(ALPHA2, prefix_country_lookup$prefix)],
#       ALPHA2
#     )
#   )

# Still doesn't cover it all so some manual coding needs to be done
# prefix_to_country_code <- data.frame(
#   old_code = c("AJ", "AY", "BC", "BK", "BP", "BU", "CE", "CJ", "CQ", "CS"),
#   new_code = c("AZ", "AQ", "BW", "BA", "SB", "BG", "LK", "KY", "MP", "CR")
# )
#
# gsoy_climate <- gsoy_climate %>%
#   rename_with(tolower) %>%
#   left_join(prefix_to_country_code, by = c("alpha2" = "old_code")) %>%
#   mutate(alpha2 = ifelse(!is.na(new_code), new_code, alpha2)) %>%
#   select(-new_code) %>%
#   rename_with(toupper)



# gsoy_climate$YEAR
# emdat_flood_storm_aggregated$year
# undesa_data_migration$year

gsoy_climate_filtered <- gsoy_climate %>%
  filter(YEAR >= 1980 & YEAR <= 2020)

gsoy_climate_coverage <- sapply(gsoy_climate_filtered, function(column) {
  mean(!is.na(column))
})

# Convert to a data frame for better presentation
coverage_table <- data.frame(
  Variable = names(gsoy_climate_coverage),
  `Coverage (%)` = gsoy_climate_coverage
)

# Identify variables with coverage less than 10%
# Remove low coverage variables
gsoy_low_coverage_variables <- names(gsoy_climate_coverage[gsoy_climate_coverage < 0.10])

gsoy_climate_filtered_cleaned <- gsoy_climate_filtered %>%
  select(-all_of(gsoy_low_coverage_variables))

# lets start connecting them together with country codes

# Download the country codes dataset
url <- "https://raw.githubusercontent.com/datasets/country-codes/main/data/country-codes.csv"
download.file(url, "country-codes.csv")

# Load the dataset into R
country_codes <- read.csv("country-codes.csv", stringsAsFactors = FALSE)

# gsoy_climate_filtered_cleaned$ALPHA2
# undesa_data_migration$m49
# emdat_flood_storm_aggregated$alpha3

# Country code lookup table
country_codes_lookup <- country_codes %>%
  select(
    alpha2 = ISO3166.1.Alpha.2,
    alpha3 = ISO3166.1.Alpha.3,
    m49 = M49
  ) %>%
  mutate(m49 = sprintf("%03d", as.numeric(m49)))

gsoy_climate_final <- gsoy_climate_filtered_cleaned %>%
  rename_with(tolower) %>%
  left_join(country_codes_lookup, by = "alpha2", relationship = "many-to-many") %>%
  rename_with(toupper)

undesa_migration_final <- undesa_data_migration %>%
  left_join(country_codes_lookup, by = "m49", relationship = "many-to-many")

emdat_diaster_final <- emdat_flood_storm_aggregated %>%
  left_join(country_codes_lookup, by = "alpha3", relationship = "many-to-many")


# population data

# Define the URL of the raw CSV file
url <- "https://raw.githubusercontent.com/datasets/population/main/data/population.csv"
download.file(url, "population.csv")

population_data <- read.csv("population.csv")

