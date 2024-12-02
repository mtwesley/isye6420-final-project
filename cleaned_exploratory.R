library(dplyr)
library(tidyr)
library(readr)
library(readxl)
library(ggplot2)

# Country codes
country_codes <- read.csv("opendata/country-codes.csv") %>%
  select(alpha2 = ISO3166.1.Alpha.2, alpha3 = ISO3166.1.Alpha.3, m49 = M49)

# Population data
population_data <- read.csv("opendata/population.csv") %>%
  select(alpha3 = `Country.Code`, country = `Country.Name`, year = Year, population = Value) %>%
  rename_with(tolower)

# Load EM-DAT disaster data
emdat_data <- read_excel("emdat/public_emdat_incl_hist_2024-11-25.xlsx", sheet = "EM-DAT Data") %>%
  filter(`Disaster Type` %in% c("Flood", "Storm")) %>%
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

# Focus on floods and storms
disaster_data <- emdat_data %>%
  group_by(year, alpha3, country, region, subregion) %>%
  summarise(
    storms = sum(disaster == "Storm", na.rm = TRUE),
    floods = sum(disaster == "Flood", na.rm = TRUE),
    deaths = sum(deaths, na.rm = TRUE),
    livesAffected = sum(livesAffected, na.rm = TRUE),
    economicDamage = sum(economicDamage, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(country_codes, by = "alpha3", relationship = "many-to-many")

# Load UNDESA migration data
undesa_data <- read_excel("undesa/undesa_pd_2020_ims_stock_origin_world.xlsx", skip = 3) %>%
  rename(country = `Region, development group, country or area of origin`,
         m49 = `Location code of origin`)

migration_data <- undesa_data %>%
  pivot_longer(cols = -c(country, m49), names_to = "year", values_to = "migrants") %>%
  group_by(country, m49, year) %>%
  summarise(migrants = sum(migrants, na.rm = TRUE), .groups = "drop") %>%
  left_join(country_codes, by = "m49", relationship = "many-to-many")

# Load and clean GSOY climate data
gsoy_data <- read_csv("noaa_ncei/gsoy-reaggregated-all-countries.csv") %>%
  rename(year = DATE, alpha2 = COUNTRY) %>%
  rename_with(tolower)

climate_data <- gsoy_data %>%
  left_join(country_codes, by = "alpha2", relationship = "many-to-many")

# Limit all data to period between 1980–2020
climate_filtered <- climate_data %>%
  filter(year >= 1980 & year <= 2020)

disaster_filtered <- disaster_data %>%
  filter(year >= 1980 & year <= 2020)

migration_filtered <- migration_data %>%
  filter(year >= 1980 & year <= 2020)

# Unify datasets on year and alpha3
climate_variables <- c(
  "year", "alpha3", "alpha2",
  "prcp_mean", "emxp_max", "emnt_min", "emxt_max",
  "tmax_max", "tmin_min", "tavg_mean"
)

disaster_climate_determinants <- climate_filtered %>%
  select(all_of(climate_variables)) %>%
  inner_join(disaster_filtered,
             by = c("year", "alpha3"),
             relationship = "many-to-many") %>%
  select(everything(), -matches("\\.x$|\\.y$"))

# Create a coverage matrix for data availability
country_coverage <- disaster_climate_determinants %>%
  group_by(alpha3) %>%
  summarise(across(where(is.numeric), ~ sum(!is.na(.)) / length(1980:2020)))

country_coverage_averages <- country_coverage %>%
  rowwise() %>%
  mutate(average_coverage = mean(c_across(where(is.numeric)), na.rm = TRUE)) %>%
  select(alpha3, average_coverage)

variable_coverage_averages <- country_coverage %>%
  summarise(across(where(is.numeric), ~ mean(.x, na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "average_coverage") %>%
  arrange(desc(average_coverage))

# Get the top 80 countries by coverage
top_80_countries <- country_coverage_averages %>%
  arrange(desc(average_coverage)) %>%
  slice_head(n = 80)

# Filter the original country_coverage to keep only the top 80
disaster_determinants_80_countries <- disaster_climate_determinants %>%
  filter(alpha3 %in% top_80_countries$alpha3)

# Subset by patterns directly without special handling for _mean or _sd
data_with_patterns <- disaster_determinants_80_countries %>%
  mutate(pattern = apply(select(., -c(alpha3, year, country, region, subregion)), 1,
                         function(row) paste0(!is.na(row), collapse = "")))

data_subsets <- split(disaster_determinants_80_countries, data_with_patterns$pattern)

data_subset_summary <- lapply(data_subsets, function(subset) {
  list(
    variables = colnames(subset)[colSums(!is.na(subset)) > 0],
    rows = nrow(subset))
})

# Summary dataframe with subsets
data_subset_summary_df <- data.frame(
  Pattern = names(data_subsets),
  Subset = sapply(data_subset_summary, function(x) paste(x$variables, collapse = ", ")),
  Rows = sapply(data_subset_summary, function(x) x$rows)) %>%
  arrange(desc(Rows))

disaster_determinants_partitioned_subsets <- list()

remaining_data <- disaster_determinants_80_countries
for (i in seq_len(nrow(data_subset_summary_df))) {
  pattern <- data_subset_summary_df$Pattern[i]
  variables <- strsplit(data_subset_summary_df$Subset[i], ", ") %>% unlist()

  subset <- remaining_data %>%
    filter(if_all(all_of(variables), ~ !is.na(.)))

  disaster_determinants_partitioned_subsets[[i]] <- subset

  remaining_data <- remaining_data %>%
    anti_join(subset, by = names(remaining_data))
}



