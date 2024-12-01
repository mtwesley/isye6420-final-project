library(reticulate)
use_python("~/.pyenv/versions/miniforge3/bin/python")

library(dplyr)
library(bayestestR)
library(posterior)
library(bayesplot)
library(readr)
library(greta)

library(greta)

filtered_determinants <- determinants %>%
  filter(
    floods > 0,
    storms > 0,
    deaths > 0,
    livesAffected > 0,
    economicDamage > 0
  )

# Check the resulting data frame
print(filtered_determinants)

# Observed data
tavg <- as_data(filtered_determinants$tavg_mean)
tmin <- as_data(filtered_determinants$tmin_mean)
tmax <- as_data(filtered_determinants$tmax_mean)
prcp <- as_data(filtered_determinants$prcp_mean)
emnt <- as_data(filtered_determinants$emnt_mean)
emxt <- as_data(filtered_determinants$emxt_mean)
emxp <- as_data(filtered_determinants$emxp_mean)
floods <- as_data(filtered_determinants$floods)
storms <- as_data(filtered_determinants$storms)
deaths <- as_data(filtered_determinants$deaths)
livesAffected <- as_data(filtered_determinants$livesAffected)
economicDamage <- as_data(filtered_determinants$economicDamage)

# Priors for predictors' effects
beta_tavg <- normal(0, 5)
beta_tmin <- normal(0, 5)
beta_tmax <- normal(0, 5)
beta_prcp <- normal(0, 5)

# Priors for effects on extreme temperatures and precipitation
beta_emnt <- normal(0, 5)
beta_emxt <- normal(0, 5)
beta_emxp <- normal(0, 5)

# Priors for coefficients linking predictors to floods and storms
beta_temp_floods <- normal(0, 5)
beta_prcp_floods <- normal(0, 5)
beta_extreme_precip_floods <- normal(0, 5)

beta_temp_storms <- normal(0, 5)
beta_prcp_storms <- normal(0, 5)
beta_extreme_precip_storms <- normal(0, 5)

# Priors for coefficients linking floods and storms to deaths, livesAffected, and economicDamage
beta_floods_deaths <- normal(0, 5)
beta_storms_deaths <- normal(0, 5)

beta_floods_livesAffected <- normal(0, 5)
beta_storms_livesAffected <- normal(0, 5)

beta_floods_economicDamage <- normal(0, 5)
beta_storms_economicDamage <- normal(0, 5)

# Variance terms for extreme events and disaster outcomes
sigma_emnt <- normal(0, 5, truncation = c(0, Inf))
sigma_emxt <- normal(0, 5, truncation = c(0, Inf))
sigma_emxp <- normal(0, 5, truncation = c(0, Inf))
sigma_floods <- normal(0, 5, truncation = c(0, Inf))
sigma_storms <- normal(0, 5, truncation = c(0, Inf))
sigma_deaths <- normal(0, 5, truncation = c(0, Inf))
sigma_livesAffected <- normal(0, 5, truncation = c(0, Inf))
sigma_economicDamage <- normal(0, 5, truncation = c(0, Inf))

# Models for extreme events
emnt_mean <- beta_tavg * tavg + beta_tmin * tmin
distribution(emnt) <- normal(emnt_mean, sigma_emnt)

emxt_mean <- beta_tavg * tavg + beta_tmax * tmax
distribution(emxt) <- normal(emxt_mean, sigma_emxt)

emxp_mean <- beta_prcp * prcp
distribution(emxp) <- normal(emxp_mean, sigma_emxp)

# Models for floods and storms
floods_mean <- beta_temp_floods * (tavg + emnt + emxt) +
  beta_prcp_floods * prcp +
  beta_extreme_precip_floods * emxp
distribution(floods) <- normal(floods_mean, sigma_floods)

storms_mean <- beta_temp_storms * (tavg + emnt + emxt) +
  beta_prcp_storms * prcp +
  beta_extreme_precip_storms * emxp
distribution(storms) <- normal(storms_mean, sigma_storms)

# Models for deaths, livesAffected, and economicDamage
deaths_mean <- beta_floods_deaths * floods + beta_storms_deaths * storms
distribution(deaths) <- normal(deaths_mean, sigma_deaths)

livesAffected_mean <- beta_floods_livesAffected * floods + beta_storms_livesAffected * storms
distribution(livesAffected) <- normal(livesAffected_mean, sigma_livesAffected)

economicDamage_mean <- beta_floods_economicDamage * floods + beta_storms_economicDamage * storms
distribution(economicDamage) <- normal(economicDamage_mean, sigma_economicDamage)

# Define the model
disaster_model <- model(
  beta_tavg, beta_tmin, beta_tmax, beta_prcp,
  beta_emnt, beta_emxt, beta_emxp,
  beta_temp_floods, beta_prcp_floods, beta_extreme_precip_floods,
  beta_temp_storms, beta_prcp_storms, beta_extreme_precip_storms,
  beta_floods_deaths, beta_storms_deaths,
  beta_floods_livesAffected, beta_storms_livesAffected,
  beta_floods_economicDamage, beta_storms_economicDamage,
  sigma_emnt, sigma_emxt, sigma_emxp,
  sigma_floods, sigma_storms, sigma_deaths,
  sigma_livesAffected, sigma_economicDamage
)

# Sample the posterior
draws <- mcmc(disaster_model, warmup = 5000, n_samples = 5000, chains = 4)

mcmc_trace(draws)
mcmc_dens(draws)

get.stats(draws)
