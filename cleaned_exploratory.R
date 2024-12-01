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
  "prcp_mean", "emxp_max", "tmax_mean", "tmin_min",
  "tavg_mean", "emnt_min", "emxt_max", "alpha2",
  "alpha3", "year", "region", "subregion"
)

disaster_climate_determinants <- climate_filtered %>%
  select(all_of(variables_of_interest)) %>%
  inner_join(disaster_filtered,
             by = c("year", "alpha3"),
             relationship = "many-to-many") %>%
  select(everything(), -matches("\\.x$|\\.y$"))

# Coverage metrics to reduce variables
dd_data_coverage <- disaster_determinants %>%
  summarise(across(where(is.numeric), ~ mean(!is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "coverage")

dd_low_data_coverage <- dd_data_coverage %>%
  filter(coverage < 0.2)

dd_unrelated_vars <- c(
  # Snow and ice variables
  "cdsd_min", "cdsd_max", "cdsd_mean", "cdsd_sd",
  "cldd_min", "cldd_max", "cldd_mean", "cldd_sd",
  "dsnd_min", "dsnd_max", "dsnd_mean", "dsnd_sd",
  "emsd_min", "emsd_max", "emsd_mean", "emsd_sd",
  "fzf0_min", "fzf0_max", "fzf0_mean", "fzf0_sd",
  "fzf1_min", "fzf1_max", "fzf1_mean", "fzf1_sd",
  "fzf2_min", "fzf2_max", "fzf2_mean", "fzf2_sd",
  "fzf3_min", "fzf3_max", "fzf3_mean", "fzf3_sd",
  "fzf4_min", "fzf4_max", "fzf4_mean", "fzf4_sd",
  "fzf5_min", "fzf5_max", "fzf5_mean", "fzf5_sd",
  "fzf6_min", "fzf6_max", "fzf6_mean", "fzf6_sd",
  "fzf7_min", "fzf7_max", "fzf7_mean", "fzf7_sd",
  "fzf8_min", "fzf8_max", "fzf8_mean", "fzf8_sd",
  "fzf9_min", "fzf9_max", "fzf9_mean", "fzf9_sd",

  # Wind variables
  "wdfi_min", "wdfi_max", "wdfi_mean", "wdfi_sd",
  "wsfi_min", "wsfi_max", "wsfi_mean", "wsfi_sd",

  # Heating and cooling metrics
  "hdsd_min", "hdsd_max", "hdsd_mean", "hdsd_sd",
  "htdd_min", "htdd_max", "htdd_mean", "htdd_sd"
)

# Remove those variables
disaster_determinants_filtered <- disaster_determinants %>%
  select(-all_of(unique(c(dd_low_data_coverage$variable, dd_unrelated_vars))))

# Check coverage across all data
ddf_data_coverage <- disaster_determinants_filtered %>%
  summarise(across(where(is.numeric), ~ mean(!is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "coverage")

disaster_determinants_cleaned <- disaster_determinants_filtered %>%
  group_by(alpha3, year, country, region, subregion) %>%
  summarise(
    across(
      starts_with(c("dp", "dt", "dx", "em", "prcp", "tavg", "tmax", "tmin", "wdfi", "wsfi")),
      ~ mean(.x, na.rm = TRUE)
    ),
    storms = sum(storms, na.rm = TRUE),
    floods = sum(floods, na.rm = TRUE),
    deaths = sum(deaths, na.rm = TRUE),
    livesAffected = sum(livesAffected, na.rm = TRUE),
    economicDamage = sum(economicDamage, na.rm = TRUE),
    .groups = "drop"
  )

# Create a coverage matrix
country_coverage <- disaster_determinants_cleaned %>%
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
disaster_determinants_80_countries <- disaster_determinants_cleaned %>%
  filter(alpha3 %in% top_80_countries$alpha3)



# Only climate variables for model
only_climate_variables <- disaster_determinants_cleaned %>%
  select(alpha3, year, country, region, subregion, ends_with("_mean"), ends_with("_sd"))

# Look for patterns on completeness
data_with_patterns <- only_climate_variables %>%
  mutate(pattern = apply(select(., ends_with("_mean"), ends_with("_sd")), 1, function(row) paste0(!is.na(row), collapse = "")))

data_subsets <- split(only_climate_variables, data_with_patterns$pattern)

data_subset_summary <- lapply(data_subsets, function(subset) {
  list(variables = colnames(subset)[colSums(!is.na(subset)) > 0], rows = nrow(subset))
})

data_subset_summary_df <- data.frame(
  Subset = sapply(data_subset_summary, function(x) paste(x$variables, collapse = ", ")),
  Rows = sapply(data_subset_summary, function(x) x$rows)) %>%
  arrange(desc(Rows))

# Step 1: Identify the subset(s) with the most rows
largest_subset_variables <- strsplit((data_subset_summary_df %>% filter(Rows == max(Rows)))$Subset, ", ") %>% unlist()

disaster_determinants_largest_subset <- disaster_determinants_cleaned %>%
  filter(if_all(all_of(largest_subset_variables), ~ !is.na(.)))





