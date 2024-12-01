library(reticulate)
use_python("~/.pyenv/versions/miniforge3/bin/python")

library(dplyr)
library(bayestestR)
library(posterior)
library(bayesplot)
library(readr)
library(greta)

library(greta)

determinants <- disaster_determinants_largest_subset

# Observed data
tavg <- as_data(determinants$tavg_mean)
tmin <- as_data(determinants$tmin_mean)
tmax <- as_data(determinants$tmax_mean)

emnt <- as_data(determinants$emnt_mean)
emxt <- as_data(determinants$emxt_mean)

prcp <- as_data(determinants$prcp_mean)
emxp <- as_data(determinants$emxp_mean)

floods <- as_data(determinants$floods)
storms <- as_data(determinants$storms)
deaths <- as_data(determinants$deaths)
livesAffected <- as_data(determinants$livesAffected)
economicDamage <- as_data(determinants$economicDamage)

# Temperature
beta_tavg <- normal(0, 10)
beta_tmin <- normal(0, 10)
beta_tmax <- normal(0, 10)

beta_temp_emnt <- normal(0, 10)
beta_temp_emxt <- normal(0, 10)

# Latent temperature
temperature <- normal(beta_tavg * tavg + beta_tmin * tmin + beta_tmax * tmax, 10)

# Extreme temperatures modeled by latent temperature
distribution(emnt) <- normal(beta_temp_emnt * temperature, 10)
distribution(emxt) <- normal(beta_temp_emxt * temperature, 10)

# Precipitation
beta_prcp <- normal(0, 10)
beta_emxp <- normal(0, 10)
beta_prcp_emxp <- normal(0, 10)

# Latent precipitation
precipitation <- normal(beta_prcp * prcp, 10)

# Extreme precipitation modeled by precipitation
distribution(emxp) <- normal(beta_prcp_emxp * precipitation, 10)

# Disaster
beta_temp_disaster <- normal(0, 10)
beta_emnt_disaster <- normal(0, 10)
beta_emxt_disaster <- normal(0, 10)

beta_prcp_disaster <- normal(0, 10)
beta_emxp_disaster <- normal(0, 10)

# Disaster occurrence modeled by temperature and precipitation and their extremes
disaster_mean <-
  beta_temp_disaster * temperature +
  beta_emnt_disaster * emnt +
  beta_emxt_disaster * emxt +
  beta_prcp_disaster * precipitation +
  beta_emxp_disaster * emxp
disaster_sd <- normal(0, 10)

disaster_rate <- normal(disaster_mean, disaster_sd)
distribution(floods) <- exponential(disaster_rate)

# Define the model
disaster_model <- model(temperature, precipitation,
                        beta_tavg, beta_tmin, beta_tmax,
                        beta_temp_emnt, beta_temp_emxt,
                        beta_prcp, beta_emxp, beta_prcp_emxp,
                        beta_temp_disaster, beta_emnt_disaster, beta_emxt_disaster,
                        beta_prcp_disaster, beta_emxp_disaster, disaster_sd, disaster_rate)

# Sample the posterior
draws <- mcmc(disaster_model, n_samples = 1000)
