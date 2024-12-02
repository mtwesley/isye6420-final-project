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
