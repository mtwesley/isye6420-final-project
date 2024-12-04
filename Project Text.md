# Data Mangling with Climate Disasters and Bayesian Modeling: Lessons from the Real World

#### Mlen-Too Wesley

#### ISYE 6420 - Fall 2024 - Final Project

#### December 1, 2024



## Introduction

I began this project interested in the intersection between climate change and migration, as this intricate relationship has garnered significant attention. Recent events, such as the devastating floods across Nigeria, Mali, and Niger, have displaced millions and exacerbated hunger crises in Africa. These incidents underscore the urgency of understanding how climate-induced disasters influence human mobility. 

<img src="https://assets.bwbx.io/images/users/iqjWHBFdfxIU/ivCHf_YKci1k/v0/-1x-1.webp" alt="https://assets.bwbx.io/images/users/iqjWHBFdfxIU/ivCHf_YKci1k/v0/-1x-1.webp" width="80%"/>

Climate events take time and as such, my research aimed to measure the causal impact using natural disasters as indicators of extreme events in a quasi-experiment design. I intended utilize Bayesian hierarchical modeling to map the progression from climate change to natural disasters, and subsequently to migration patterns and employ methodologies like regression discontinuity and difference-in-differences to analyze this relationship. I was too ambitious. 

<img src="/Users/mtwesley/Dropbox/Courses/GATech/ISYE 6420 - Bayesian Statistics/Project/pathway.png" width="70%"  alt="img" />

Following an extensive phase of data collection and cleaning, seeking datasets that could provide reliable measures of climate change effects, natural disaster occurrences, and migration statistics, the migration data I had was insufficient in scope and granularity to support my project. 

Given these constraints, I refocused my analysis to just the relationship between climate change and natural disasters. This adaptation involved developing a simplified model that utilized Bayesian hierarchical modeling techniques to explore and map out the interactions between climatic variables and natural disaster events. 

This paper outlines the revised research approach, detailing the methodologies employed, the data utilized, and the insights gained from the analysis. It also discusses the setbacks encountered during the study and how these influenced the project’s trajectory. Moreover, it showcases my real life effort working with incomplete data to do Bayesian analysis.



## Data Collection

With climate change data, I found more sources that provided maps and satellite imagery than tabular data. However, I eventually stumbled upon the Global Historical Climatology Network (GHCN) managed by the National Oceanic and Atmospheric Administration (NOAA), which has an extensive collection of records globally, that is also accessible online. 

I utilized the NOAA Global Summary of the Year (GSOY) data which offers detailed annual climate data. This dataset summarized broader climatic trends and extremes. I actually attempted to use the Global Surface Summary of the Month (GSOM)  first, however this was challenging due to its size and complexity. I knew climate and migration was summarized by year, so I went with GSOY.

For natural disaster data, the EM-DAT International Disaster Database by the Centre for Research on the Epidemiology of Disasters (CRED) is a leading source, providing comprehensive historical records of disaster events worldwide, including their impacts on populations and economies. There are some caveats, relating to how past data collection may be unreliable.

Migration data, however, is often more fragmented and challenging to consolidate due to the complexity of migration patterns and the variability in data collection methods across regions. 

- The United Nations Department of Economic and Social Affairs (UNDESA) provides international migration stock and flow data, detailing cross-border population movements at periodic intervals, making it one of the most comprehensive sources for global migration statistics. 
- The World Bank’s Migration and Remittances Data portal offers datasets focused on migration flows and associated financial remittances, which are critical for understanding the economic dynamics of migration. The International Organization for Migration (IOM) manages the Displacement Tracking Matrix (DTM), providing real-time data on internal displacement often linked to natural disasters, conflicts, and other crises. 
- The KNOMAD (Global Knowledge Partnership on Migration and Development) platform complements these datasets by offering open-access data on migration trends, policies, and their socio-economic implications. 
- The Determinants of International Migration (DEMIG) database, curated by the International Migration Institute, provides detailed data on migration flows, including bilateral migration flow estimates and immigration policies, making it a valuable resource for studying the drivers and patterns of migration over time. 

I made a first attempt to use the DEMIG database, but it was very limited, focusing on a handful of countries. So I opted for the UNDESA data, however this was limited to 5-year periods from 1990 to 2020. Unfortunately, this dataset's limitations significantly shaped the study's scope, emphasizing the need for more comprehensive migration datasets in future research. With enough time, I can revisit the data and complete the project as I originally envisioned. 

Finally, on a side note, I found a lot of national, sub-national and regional migration data, collected from national census data. However, this was even more difficult to incorporate into my project, and was likely incorporated into the larger DEMIG and UNDESA databases anyways. 

The data and source codes are available at: https://github.com/mtwesley/isye6420-final-project

Here’s a quick breakdown:

- **demig/demig-total-migration-database_v1-5.xlsx:**  Migration data from the DEMIG project
- **emdat/emdat-country-profiles_2024_11_25.xlsx:** Country-level disaster profiles from EM-DAT with disaster frequency, types, and impacts, deaths, economic loss
- **noaa_ncei:** Multiple subfolders and files for organizing large climate datasets from NOAA National Centers for Environmental Information
- **noaa_ncei/gsoy-aggregated-all-countries.csv and noaa_ncei/gsoy-reaggregated-all-countries.csv**: Final merged, processed and reprocessed GSOY datasets, and aggregated at the country level
- **opencage/opencage-ghcnd-prefix-lookup.csv:** Mapping information for OpenCage geolocation services and GHCND station prefixes to geolocating or identifying climate station data
- **opendata/country-codes.csv:** Mapping relationships between country names and codes (ISO Alpha-2, Alpha-3, or M49)  to harmonize datasets with different conventions for countries
- **opendata/population.csv**: Population data for countries and regions by year as a demographic indicator
- **undesa/undesa_pd_2020_ims_stock_by_sex_destination_and_origin.xlsx and udesa/undesa_pd_2020_ims_stock_origin_world.xlsx:** Excel files from the UNDESA with migration stock data categorized by destination and origin countries up to the year 2020



## Data Preparation

The preparation of the selected data involved extensive cleaning and manipulation using both Bash and R scripts. Such as

```R
input_dir <- "noaa_ncei/gsoy-latest"
output_dir <- "noaa_ncei/gsoy-merged"

if (!dir.exists(input_dir)) stop("Input directory does not exist: ", input_dir)
if (!dir.exists(output_dir)) dir.create(output_dir, showWarnings = FALSE)

file_list <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)
get_country_code <- function(filename) substr(basename(filename), 1, 2)
country_files_map <- split(file_list, sapply(file_list, get_country_code))

for (country_code in names(country_files_map)) {
  files <- country_files_map[[country_code]]
  country_data <- data.frame(matrix(ncol = length(variables), nrow = 0))
  colnames(country_data) <- variables
  cat("Processing country:", country_code, "\n")

  for (file_path in files) {
    cat("  Reading file:", file_path, "\n")
    file_data <- read.csv(file_path, stringsAsFactors = FALSE)

    filtered_data <- file_data[, intersect(colnames(file_data), variables), drop = FALSE]
    filtered_data$COUNTRY <- country_code

    for (col in setdiff(variables, colnames(filtered_data))) {
      filtered_data[[col]] <- NA
    }
    filtered_data <- filtered_data[, variables]

    country_data <- rbind(country_data, filtered_data)
  }

  output_file <- file.path(output_dir, paste0(country_code, ".csv"))
  write.csv(country_data, output_file, row.names = FALSE, na = "")
  cat("  Merged file written for:", country_code, "\n")
}
```

Once merged, data often had to be aggregated or re-aggregated if there were problems or mistakes along the way. 

```R
input_dir <- "noaa_ncei/gsoy-remerged"
output_dir <- "noaa_ncei/gsoy-reaggregated"

if (!dir.exists(input_dir)) stop("Input directory does not exist: ", input_dir)
if (!dir.exists(output_dir)) dir.create(output_dir, showWarnings = FALSE)

file_list <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)

for (file_path in file_list) {
  cat("Processing:", file_path, "\n")

  data <- read.csv(file_path, stringsAsFactors = FALSE)
  non_numeric_cols <- c("COUNTRY", "DATE")
  numeric_cols <- setdiff(colnames(data), non_numeric_cols)

  aggregated_data <- data %>%
    group_by(COUNTRY, DATE) %>%
    summarize(
      across(
        all_of(numeric_cols),
        list(
          MIN = ~ min(., na.rm = TRUE),
          MAX = ~ max(., na.rm = TRUE),
          MEAN = ~ mean(., na.rm = TRUE),
          SD = ~ sd(., na.rm = TRUE)
        ),
        .names = "{.col}_{.fn}"
      ),
      .groups = "drop" # Ensures the result is ungrouped
    ) %>%
    arrange(DATE) %>%
    mutate(across(everything(), ~ ifelse(is.infinite(.), NA, .)))

  output_file <- file.path(output_dir, basename(file_path))
  write.csv(aggregated_data, output_file, row.names = FALSE, na = "")
  cat("  Written:", output_file, "\n")
}
```

The repository contains many other similar scripts used during the data collection and cleaning process. These aided in the process of gathering, merging, and aggregating data for us in the analysis. 

Now, with the data on my computer, I explored the variables available to understand how to combine them into one unified dataset and ensuring data integrity, such as handling missing data and standardizing formats across datasets. 

For example, the climate data was from weather stations. I could recognize them as two-letter country codes. However, when unifying climate data with natural disaster data, there were many that did not match. I then realized that the coding changes over time. To adjust for this, I had to use an API to map GPS coordinates to current countries, build lookup tables, and remerge and re-aggregate the data.  Which took hours.

Here are some examples of the climate data:

![image-20241201215251926](/Users/mtwesley/Library/Application Support/typora-user-images/image-202412012152519262.png)

And the migration data:

![image-20241201215405338](/Users/mtwesley/Library/Application Support/typora-user-images/image-20241201215405338.png)

And the disaster data:

![image-20241201215441792](/Users/mtwesley/Library/Application Support/typora-user-images/image-20241201215441792.png)

Overall, the preparation phase was both time-intensive and somewhat incomplete, as I was not able to prepare the migration data in time for submitting the project. However, it was a good experience and has set a solid foundation for subsequent modeling efforts.

<div class="page-break"></div>

```R
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

```



## Model overview and approach 

A hierarchical Bayesian model was used to investigate the relationship between climate variables, extreme weather events, and natural disasters, specifically floods and storms. The choice of disasters (floods and storms) was chosen due to its variability across multiple countries and regions, which was validated with the data.

With Bayesian modeling, I could incorporate uncertainty at multiple levels and map out the system hierarchically. The model is designed to capture the interplay between average climatic conditions, extreme weather events, and the occurrence of natural disasters, while allowing for flexibility in the specification of uncertainty through prior distributions.

The modeling framework rests on two primary components: 

1. Climate variables on extreme weather events
2. Effect of both climate variables and extreme weather events on disasters such as floods and storms

In future studies, I hope to finally link this with migration.



#### Observed Data

The observed variables include temperature, precipitation, extreme weather variables, and disaster occurrence counts. These variables form the foundational inputs for the model:

* **Temperature variables**: Mean temperature ($t_{\text{avg}}$), minimum temperature ($t_{\text{min}}$), and maximum temperature ($t_{\text{max}}$)
* **Precipitation variable**: Mean precipitation ($p$)
* **Extreme weather events**: Minimum extreme temperature $(e_{\text{mnt}})$, maximum extreme temperature $(e_{\text{mxt}})$, and maximum extreme precipitation $(e_{\text{mxp}})$
* **Disaster counts**: Flood $f$ and storm $s$ occurrences

These data are preprocessed to ensure completeness and consistency, with missing data excluded to prevent bias in inference. Each variable represents an aggregated yearly value at the country level. In the future, I could also measure grouped effects at regional and subregional levels.



#### Non-informative priors for predictors and variance terms

Due to lack of domain expertise, the model adopts weakly informative priors for the coefficients linking predictors to outcomes. Priors are necessary in Bayesian analysis to express initial beliefs about parameter values, while allowing flexibility for the data to dominate inference.

The coefficients for the relationship between climate variables and extreme events, as well as between extreme events and disasters, are modeled using normal distributions centered at zero:

$$
\beta \sim \mathcal{N}(0, 10) \nonumber
$$

This prior reflects the assumption that, a priori, the relationships between these variables are likely centered around zero with moderate uncertainty. For variance terms related to extreme events and disaster outcomes, we use truncated normal distributions:

$$
\sigma \sim \mathcal{N}(0, 5), \, \text{truncated to } (0, \infty) \nonumber
$$

The truncation ensures that variance terms are strictly positive, reflecting their role in modeling uncertainty.



#### Modeling extreme weather events

Extreme weather events are modeled as outcomes of temperature and precipitation variables. The rationale for this modeling choice is that climatic conditions, such as temperature and precipitation, influence the likelihood and severity of extremes.

* Extreme Minimum Temperature ( $e_{\text{mnt}}$ ): The expected value of extreme minimum temperature is modeled as a linear combination of mean temperature $( t_{\text{avg}} )$ and minimum temperature $( t_{\text{min}} )$ and the observed  $e_{\text{mnt}} $ is assumed to follow a normal distribution:

$$
\nonumber \mu_{\text{emnt}} = \beta_{\text{tavg}} \cdot t_{\text{avg}} + \beta_{\text{tmin}} \cdot t_{\text{min}}
$$

$$
e_{\text{mnt}} \sim \mathcal{N}(\mu_{\text{emnt}}, \sigma_{\text{emnt}}) \nonumber
$$

* Extreme Maximum Temperature $( e_{\text{mxt}} )$: Similarly, the expected value of extreme maximum temperature is influenced by mean temperature $( t_{\text{avg}} )$ and maximum temperature$( t_{\text{max}} )$:

$$
\mu_{\text{emxt}} = \beta_{\text{tavg}} \cdot t_{\text{avg}} + \beta_{\text{tmax}} \cdot t_{\text{max}} \nonumber
$$

$$
e_{\text{mxt}} \sim \mathcal{N}(\mu_{\text{emxt}}, \sigma_{\text{emxt}}) \nonumber
$$

* Extreme Precipitation $( e_{\text{mxp}} )$: The expected value of extreme precipitation is modeled as proportional to mean precipitation $( p )$:

$$
\mu_{\text{emxp}} = \beta_{\text{prcp}} \cdot p \nonumber
$$

$$
e_{\text{mxp}} \sim \mathcal{N}(\mu_{\text{emxp}}, \sigma_{\text{emxp}}) \nonumber
$$

These ensure that extreme weather events are directly tied to climate variables while incorporating uncertainty in their predictions.





#### Modeling natural disasters

Natural disasters, such as floods $( f )$ and storms $( s )$, are modeled as Poisson processes, where the rate parameters ( $\lambda_f $ and $ \lambda_s$ ) are functions of climate variables and extreme events. The Poisson distribution is chosen due to its suitability for modeling count data, such as disaster occurrences, but due to model design, the data is exponentiated prior to being used as a rate.

* **Floods:** The log-rate of floods is expressed as:
  $$
  \log \lambda_f = \beta_{\text{temp-floods}} \cdot (t_{\text{avg}} + e_{\text{mnt}} + e_{\text{mxt}}) +
  \beta_{\text{prcp-floods}} \cdot p + \beta_{\text{extreme-precip-floods}} \cdot e_{\text{mxp}} \nonumber
  $$

* Storms: The log-rate of storms is similarly modeled:
  $$
  \log \lambda_s = \beta_{\text{temp-storms}} \cdot (t_{\text{avg}} + e_{\text{mnt}} + e_{\text{mxt}}) +
  \beta_{\text{prcp-storms}} \cdot p + \beta_{\text{extreme-precip-storms}} \cdot e_{\text{mxp}} \nonumber
  $$
  



#### Sampling and inference

Inference is conducted using Markov Chain Monte Carlo (MCMC) sampling, enabling estimation of posterior distributions for all parameters, including  $\beta$  coefficients and  $\sigma$  variance terms. 

The hierarchical structure of the model reflects the natural order of influence, that climate variables affect extreme weather events, which in turn drive disaster outcomes. This approach aligns with theoretical expectations and allows for the incorporation of uncertainty at every stage. The use of Poisson distributions for disasters is particularly suited to count data, while the normal distributions for extreme events offer flexibility in modeling continuous outcomes.



```R
library(greta)

determinants <- disaster_determinants_partitioned_subsets[[1]]

# Observed data
tavg <- as_data(determinants$tavg_mean)
tmin <- as_data(determinants$tmin_min)
tmax <- as_data(determinants$tmax_max)

prcp <- as_data(determinants$prcp_mean)

emnt <- as_data(determinants$emnt_min)
emxt <- as_data(determinants$emxt_max)
emxp <- as_data(determinants$emxp_max)

floods <- as_data(determinants$floods)
storms <- as_data(determinants$storms)

# Priors for predictors' effects
beta_tavg <- normal(0, 10)
beta_tmin <- normal(0, 10)
beta_tmax <- normal(0, 10)
beta_prcp <- normal(0, 10)

# Priors for effects on extreme temperatures and precipitation
beta_emnt <- normal(0, 10)
beta_emxt <- normal(0, 10)
beta_emxp <- normal(0, 10)

# Priors for coefficients linking predictors to floods
beta_temp_floods <- normal(0, 10)
beta_prcp_floods <- normal(0, 10)
beta_extreme_precip_floods <- normal(0, 10)

# Priors for coefficients linking predictors to storms
beta_temp_storms <- normal(0, 10)
beta_prcp_storms <- normal(0, 10)
beta_extreme_precip_storms <- normal(0, 10)

# Variance terms for extreme events
sigma_emnt <- normal(0, 5, truncation = c(0, Inf))
sigma_emxt <- normal(0, 5, truncation = c(0, Inf))
sigma_emxp <- normal(0, 5, truncation = c(0, Inf))

# Models for extreme events
emnt_mean <- beta_tavg * tavg + beta_tmin * tmin
distribution(emnt) <- normal(emnt_mean, sigma_emnt)

emxt_mean <- beta_tavg * tavg + beta_tmax * tmax
distribution(emxt) <- normal(emxt_mean, sigma_emxt)

emxp_mean <- beta_prcp * prcp
distribution(emxp) <- normal(emxp_mean, sigma_emxp)

# Floods modeled as Poisson with exp() rate
floods_rate <- exp(
  beta_temp_floods * (tavg + emnt + emxt) +
    beta_prcp_floods * prcp +
    beta_extreme_precip_floods * emxp
)
distribution(floods) <- poisson(floods_rate)

# Storms modeled as Poisson with exp() rate
storms_rate <- exp(
  beta_temp_storms * (tavg + emnt + emxt) +
    beta_prcp_storms * prcp +
    beta_extreme_precip_storms * emxp
)
distribution(storms) <- poisson(storms_rate)

# Define the model
disaster_model <- model(
  beta_tavg, beta_tmin, beta_tmax, beta_prcp,
  beta_emnt, beta_emxt, beta_emxp,
  beta_temp_floods, beta_prcp_floods, beta_extreme_precip_floods,
  beta_temp_storms, beta_prcp_storms, beta_extreme_precip_storms,
  sigma_emnt, sigma_emxt, sigma_emxp
)

# Sample the posterior
draws <- mcmc(disaster_model, warmup = 4000, n_samples = 10000, chains = 4)

mcmc_trace(draws)
mcmc_dens(draws)

get.stats(draws)

```



Trace plots were pretty horrible. 

![PoissonTracePlots](/Users/mtwesley/Dropbox/Courses/GATech/ISYE 6420 - Bayesian Statistics/Project/PoissonTracePlots.png)

Density plots were no better:

![PoissonDensPlots](/Users/mtwesley/Dropbox/Courses/GATech/ISYE 6420 - Bayesian Statistics/Project/PoissonDensPlots.png)



![image-20241201232233315](/Users/mtwesley/Library/Application Support/typora-user-images/image-20241201232233315.png)



<div class="page-break"></div>

## Alternative model for comparison  

Given the poor results, I tested another model. This second model is also designed to explore the relationship between climate variables, extreme events, and natural disasters (floods and storms) by employing a normal distribution for the disaster outcomes ( $f$  and  $s$ ) instead of the Poisson-log-link approach in the first model. 

By using normal distributions, this model assumes that disaster occurrences are continuous rather than discrete counts, which would have been useful for other metrics, but it also allows for a simpler probabilistic structure.



#### Observed Data
As in the first model, the observed data comprises climate variables, extreme events, and disaster outcomes:

- **Climate variables:** 
  - $t_{\text{avg}}$ (mean temperature)
  - $t_{\text{min}}$ (minimum temperature)
  - $t_{\text{max}}$ (maximum temperature)
  - $p$ (mean precipitation)

- **Extreme weather events:** 
  - $e_{\text{mnt}}$ (minimum extreme temperature)
  - $e_{\text{mxt}}$ (maximum extreme temperature)
  - $e_{\text{mxp}}$ (extreme precipitation)

- **Disaster counts: $**f$ (floods) and $s$ (storms)



The priors remain identical to those in the first model, reflecting the same assumptions about uncertainty and initial beliefs:

- Coefficients for relationships ($\beta$)  for linking climate variables to extreme events and extreme events to disaster outcomes
  $$
  \beta \sim \mathcal{N}(0, 10) \nonumber
  $$
  
- Variance terms ($\sigma$) for extreme events and disasters:
  $$
  \sigma \sim \mathcal{N}(0, 5) \text{ truncated to } (0, \infty) \nonumber
  $$
  

As with the first model, extreme weather events are modeled as functions of climate variables:

1. **Extreme Minimum Temperature** ($e_{\text{mnt}}$):
   $$
   \mu_{\text{emnt}} = \beta_{\text{tavg}} \cdot t_{\text{avg}} + \beta_{\text{tmin}} \cdot t_{\text{min}} \nonumber
   $$
   $$
   e_{\text{mnt}} \sim \mathcal{N}(\mu_{\text{emnt}}, \sigma_{\text{emnt}}) \nonumber
   $$

2. **Extreme Maximum Temperature** ($e_{\text{mxt}}$):
   $$
   \mu_{\text{emxt}} = \beta_{\text{tavg}} \cdot t_{\text{avg}} + \beta_{\text{tmax}} \cdot t_{\text{max}} \nonumber
   $$
   $$
   e_{\text{mxt}} \sim \mathcal{N}(\mu_{\text{emxt}}, \sigma_{\text{emxt}}) \nonumber
   $$

3. **Extreme Precipitation** ($e_{\text{mxp}}$):
   $$
   \mu_{\text{emxp}} = \beta_{\text{prcp}} \cdot p \nonumber
   $$
   $$
   e_{\text{mxp}} \sim \mathcal{N}(\mu_{\text{emxp}}, \sigma_{\text{emxp}}) \nonumber
   $$

Finally, floods ($f$) and storms ($s$) are modeled as continuous outcomes, which is distinct from the Poisson process used in the first model:

1. **Floods**:
   $$
   \mu_f = \beta_{\text{temp\_floods}} \cdot (t_{\text{avg}} + e_{\text{mnt}} + e_{\text{mxt}}) +
   \beta_{\text{prcp\_floods}} \cdot p +
   \beta_{\text{extreme\_precip\_floods}} \cdot e_{\text{mxp}} \nonumber
   $$
   $$
   f \sim \mathcal{N}(\mu_f, \sigma_f) \nonumber
   $$

2. **Storms**:
   $$
   \mu_s = \beta_{\text{temp\_storms}} \cdot (t_{\text{avg}} + e_{\text{mnt}} + e_{\text{mxt}}) +
   \beta_{\text{prcp\_storms}} \cdot p +
   \beta_{\text{extreme\_precip\_storms}} \cdot e_{\text{mxp}} \nonumber
   $$
   $$
   s \sim \mathcal{N}(\mu_s, \sigma_s) \nonumber
   $$



```R
library(greta)

determinants <- disaster_determinants_partitioned_subsets[[1]]

# Observed data
tavg <- as_data(determinants$tavg_mean)
tmin <- as_data(determinants$tmin_min)
tmax <- as_data(determinants$tmax_max)

prcp <- as_data(determinants$prcp_mean)

emnt <- as_data(determinants$emnt_min)
emxt <- as_data(determinants$emxt_max)
emxp <- as_data(determinants$emxp_max)

floods <- as_data(determinants$floods)
storms <- as_data(determinants$storms)

# Priors for predictors' effects
beta_tavg <- normal(0, 10)
beta_tmin <- normal(0, 10)
beta_tmax <- normal(0, 10)
beta_prcp <- normal(0, 10)

# Priors for effects on extreme temperatures and precipitation
beta_emnt <- normal(0, 10)
beta_emxt <- normal(0, 10)
beta_emxp <- normal(0, 10)

# Priors for coefficients linking predictors to floods
beta_temp_floods <- normal(0, 10)
beta_prcp_floods <- normal(0, 10)
beta_extreme_precip_floods <- normal(0, 10)

# Priors for coefficients linking predictors to storms
beta_temp_storms <- normal(0, 10)
beta_prcp_storms <- normal(0, 10)
beta_extreme_precip_storms <- normal(0, 10)

# Variance terms for extreme events and disaster outcomes
sigma_emnt <- normal(0, 5, truncation = c(0, Inf))
sigma_emxt <- normal(0, 5, truncation = c(0, Inf))
sigma_emxp <- normal(0, 5, truncation = c(0, Inf))
sigma_floods <- normal(0, 5, truncation = c(0, Inf))
sigma_storms <- normal(0, 5, truncation = c(0, Inf))

# Models for extreme events
emnt_mean <- beta_tavg * tavg + beta_tmin * tmin
distribution(emnt) <- normal(emnt_mean, sigma_emnt)

emxt_mean <- beta_tavg * tavg + beta_tmax * tmax
distribution(emxt) <- normal(emxt_mean, sigma_emxt)

emxp_mean <- beta_prcp * prcp
distribution(emxp) <- normal(emxp_mean, sigma_emxp)

# Model for floods
floods_mean <- beta_temp_floods * (tavg + emnt + emxt) +
  beta_prcp_floods * prcp +
  beta_extreme_precip_floods * emxp
distribution(floods) <- normal(floods_mean, sigma_floods)

# Model for storms
storms_mean <- beta_temp_storms * (tavg + emnt + emxt) +
  beta_prcp_storms * prcp +
  beta_extreme_precip_storms * emxp
distribution(storms) <- normal(storms_mean, sigma_storms)

# Define the model
disaster_model <- model(
  beta_tavg, beta_tmin, beta_tmax, beta_prcp,
  beta_emnt, beta_emxt, beta_emxp,
  beta_temp_floods, beta_prcp_floods, beta_extreme_precip_floods,
  beta_temp_storms, beta_prcp_storms, beta_extreme_precip_storms,
  sigma_emnt, sigma_emxt, sigma_emxp,
  sigma_floods, sigma_storms
)

# Sample the posterior
draws <- mcmc(disaster_model, warmup = 2000, n_samples = 5000, chains = 4)

mcmc_trace(draws)
mcmc_dens(draws)

get.stats(draws)
```



With the following trace:

![NormalTracePlot](/Users/mtwesley/Dropbox/Courses/GATech/ISYE 6420 - Bayesian Statistics/Project/NormalTracePlot.png)

And density plot:

![NormalDensPlots](/Users/mtwesley/Dropbox/Courses/GATech/ISYE 6420 - Bayesian Statistics/Project/NormalDensPlots.png)

And results:

![image-20241201225416509](/Users/mtwesley/Library/Application Support/typora-user-images/image-20241201225416509.png)



The Poisson model is more aligned with the nature of disaster data, as floods and storms are discrete events that cannot be negative or fractional. The inclusion of a log-link transformation ensures that the rate parameter is positive, making it more interpretable in terms of multiplicative relationships. However, this approach introduces computational complexity, especially for hierarchical models.

The second model is not realist as it assumes disaster occurrences are continuous, but it is simpler to implement and slightly more computationally efficient. It may not accurately capture the discrete nature of the data, particularly for countries with low disaster counts, but it may be useful for future analysis with more levels if migration was added.



## Conclusions 

Throughout the process, several setbacks were encountered, primarily concerning data availability and model complexity. The initial lack of suitable migration data compelled a focus shift solely to the relationship between climate change and natural disasters. Additionally, the high complexity of the chosen models led to computational difficulties and extended processing times, impacting my project timeline.

The final models demonstrated that some relationship does exist between climate variables and the incidence of natural disasters. None of the models, however, were significant enough. More design and testing is necessary, and will be worked on in the future. Overall, these results were promising, even if the absence of migration data in the analysis was a notable limitation. The findings provide a basis for understanding how climate extremes can be modeled as an influencer of disaster occurrences.



## References

Centre for Research on the Epidemiology of Disasters (CRED). EM-DAT: The International Disaster Database. Retrieved from https://www.emdat.be

National Oceanic and Atmospheric Administration (NOAA). Global Surface Summary of the Month (GSOM). NOAA National Centers for Environmental Information. Retrieved from https://www.ncei.noaa.gov

United Nations Department of Economic and Social Affairs (UNDESA). International Migration Database. Retrieved from https://www.un.org/development/desa/pd/content/international-migration-database

Beck, H. E., Zimmermann, N. E., McVicar, T. R., Vergopolan, N., Berg, A., & Wood, E. F. (2018). Present and future Köppen-Geiger climate classification maps at 1-km resolution. Scientific Data, 5(1), 180214. Retrieved from https://doi.org/10.1038/sdata.2018.214

World Bank Climate Change Knowledge Portal (CCKP). Retrieved from https://climateknowledgeportal.worldbank.org/

NOAA Global Historical Climatology Network (GHCN). Retrieved from https://www.ncei.noaa.gov/products/land-based-station/global-historical-climatology-network-monthly

ECA&D. European Climate Assessment & Dataset. Retrieved from https://www.ecad.eu/

Climate TRACE. Retrieved from https://www.climatetrace.org/

