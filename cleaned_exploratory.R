library(dplyr)
library(tidyr)
library(readr)
library(readxl)
library(ggplot2)

# Country codes
country_codes <- read.csv("opendata/country-codes.csv") %>%
  select(alpha2 = ISO3166.1.Alpha.2, alpha3 = ISO3166.1.Alpha.3, m49 = M49)

# Station prefixes to fix country codes
station_prefix_to_country_code <- data.frame(
  prefix = c("AJ", "AY", "BC", "BK", "BP", "BU", "CE", "CJ", "CQ", "CS", "CT", "DA", "DR", "EI", "EN", "EU", "EZ",
             "FG", "FP", "FS", "HO", "IC", "IV", "JA", "JN", "JQ", "JU", "KS", "KT", "KU", "LE", "LG", "LH", "LO",
             "MB", "MI", "MJ", "NH", "NN", "NS", "PC", "PO", "PP", "RI", "RM", "RP", "RQ", "SF", "SP", "SU", "SW",
             "TE", "TI", "TS", "TU", "TX", "UC", "UK", "UP", "UV", "VM", "VQ", "WA", "WI", "WQ", "WZ", "ZI"),
  country_code = c("AZ", "AQ", "BW", "BA", "SB", "BG", "LK", "KY", "MP", "CR", "CF", "DK", "DO", "IE", "EE", "FR", "CZ",
                   "FR", "FR", "FR", "HN", "IS", "CI", "JP", "NO", "US", "FR", "KR", "AU", "KW", "LB", "EE", "LT", "SK",
                   "FR", "MW", "ME", "VU", "NL", "SR", "PN", "PT", "PG", "RS", "MH", "PH", "US", "ZA", "ES", "SD", "SE",
                   "FR", "UZ", "TN", "TR", "TM", "NL", "GB", "UA", "BF", "VN", "US", "NA", "MA", "US", "SZ", "ZW")
)

# Population data
population_data <- read.csv("opendata/population.csv") %>%
  select(alpha3 = `Country.Code`, country = `Country.Name`, year = Year, population = Value) %>%
  rename_with(tolower)

# Load EM-DAT data and filter for natural disasters
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

# Load UNDESA migration data and process for long format
undesa_data <- read_excel("undesa/undesa_pd_2020_ims_stock_origin_world.xlsx", skip = 3) %>%
  rename(country = `Region, development group, country or area of origin`,
         m49 = `Location code of origin`)

migration_data <- undesa_data %>%
  pivot_longer(cols = -c(country, m49), names_to = "year", values_to = "migrants") %>%
  group_by(country, m49, year) %>%
  summarise(migrants = sum(migrants, na.rm = TRUE), .groups = "drop") %>%
  left_join(country_codes, by = "m49", relationship = "many-to-many")

# Load and clean GSOY climate data
gsoy_data <- read_csv("noaa_ncei/gsoy-aggregated-all-countries.csv") %>%
  rename(year = DATE, alpha2 = COUNTRY) %>%
  rename_with(tolower) %>%
  left_join(station_prefix_to_country_code,
            by = c("alpha2" = "prefix"),
            relationship = "many-to-many") %>%
  mutate(alpha2 = coalesce(country_code, alpha2)) %>%
  select(-country_code)

# Map GSOY prefixes to ISO codes
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
disaster_determinants <- climate_filtered %>%
  inner_join(disaster_filtered,
             by = c("year", "alpha3"),
             relationship = "many-to-many") %>%
  select(-matches("\\.x$|\\.y$"))

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



