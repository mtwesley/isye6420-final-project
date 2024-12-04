get.stats <- function(samples) {
  samples <- posterior::as_draws(samples)
  stats <- dplyr::left_join(
    summary(samples),
    dplyr::rename(bayestestR::hdi(samples), variable = Parameter),
    by = "variable")
  
  stats <- dplyr::select(stats, -CI)
  stats <- dplyr::rename(stats, hdi5 = CI_low, hdi95 = CI_high)
  stats <- dplyr::relocate(stats, hdi5, hdi95, .after = q95)
  
  return(as.data.frame(stats))
}
