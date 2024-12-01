library(reticulate)
use_python("~/.pyenv/versions/miniforge3/bin/python")

library(dplyr)
library(bayestestR)
library(posterior)
library(bayesplot)
library(readr)
library(greta)

library(greta)

# Observed data
tavg <- as_data(determinants$tavg_mean)
tmin <- as_data(determinants$tmin_mean)
tmax <- as_data(determinants$tmax_mean)
prcp <- as_data(determinants$prcp_mean)
emnt <- as_data(determinants$emnt_mean)
emxt <- as_data(determinants$emxt_mean)
emxp <- as_data(determinants$emxp_mean)
floods <- as_data(determinants$floods)
storms <- as_data(determinants$storms)
deaths <- as_data(determinants$deaths)
livesAffected <- as_data(determinants$livesAffected)
economicDamage <- as_data(determinants$economicDamage)

# Priors for predictors' effects
beta_tavg <- normal(0, 5)
beta_tmin <- normal(0, 5)
beta_tmax <- normal(0, 5)
beta_prcp <- normal(0, 5)

# Priors for effects on extreme temperatures and precipitation
beta_emnt <- normal(0, 5)
beta_emxt <- normal(0, 5)
beta_emxp <- normal(0, 5)

# Priors for coefficients linking predictors to outcomes
beta_temp_floods <- normal(0, 5)
beta_prcp_floods <- normal(0, 5)
beta_extreme_precip_floods <- normal(0, 5)

beta_temp_storms <- normal(0, 5)
beta_prcp_storms <- normal(0, 5)
beta_extreme_precip_storms <- normal(0, 5)

beta_temp_deaths <- normal(0, 5)
beta_prcp_deaths <- normal(0, 5)
beta_extreme_precip_deaths <- normal(0, 5)

beta_temp_livesAffected <- normal(0, 5)
beta_prcp_livesAffected <- normal(0, 5)
beta_extreme_precip_livesAffected <- normal(0, 5)

beta_temp_economicDamage <- normal(0, 5)
beta_prcp_economicDamage <- normal(0, 5)
beta_extreme_precip_economicDamage <- normal(0, 5)

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

# Model for deaths
deaths_mean <- beta_temp_deaths * (tavg + emnt + emxt) +
  beta_prcp_deaths * prcp +
  beta_extreme_precip_deaths * emxp
distribution(deaths) <- normal(deaths_mean, sigma_deaths)

# Model for livesAffected
livesAffected_mean <- beta_temp_livesAffected * (tavg + emnt + emxt) +
  beta_prcp_livesAffected * prcp +
  beta_extreme_precip_livesAffected * emxp
distribution(livesAffected) <- normal(livesAffected_mean, sigma_livesAffected)

# Model for economicDamage
economicDamage_mean <- beta_temp_economicDamage * (tavg + emnt + emxt) +
  beta_prcp_economicDamage * prcp +
  beta_extreme_precip_economicDamage * emxp
distribution(economicDamage) <- normal(economicDamage_mean, sigma_economicDamage)

# Define the model
disaster_model <- model(
  beta_tavg, beta_tmin, beta_tmax, beta_prcp,
  beta_emnt, beta_emxt, beta_emxp,
  beta_temp_floods, beta_prcp_floods, beta_extreme_precip_floods,
  beta_temp_storms, beta_prcp_storms, beta_extreme_precip_storms,
  beta_temp_deaths, beta_prcp_deaths, beta_extreme_precip_deaths,
  beta_temp_livesAffected, beta_prcp_livesAffected, beta_extreme_precip_livesAffected,
  beta_temp_economicDamage, beta_prcp_economicDamage, beta_extreme_precip_economicDamage,
  sigma_emnt, sigma_emxt, sigma_emxp,
  sigma_floods, sigma_storms, sigma_deaths,
  sigma_livesAffected, sigma_economicDamage
)

# Sample the posterior
draws <- mcmc(disaster_model, warmup = 2000, n_samples = 5000, chains = 4)
