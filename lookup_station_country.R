library(httr)
library(dplyr)

# Load and parse the input file
file_path <- "noaa_ncei/ghcnd-stations-filtered-unique.txt"
stations_data <- readLines(file_path)

stations_df <- data.frame(
  prefix = substr(stations_data, 1, 2),
  station_id = substr(stations_data, 1, 11),
  latitude = as.numeric(substr(stations_data, 13, 20)),
  longitude = as.numeric(substr(stations_data, 22, 30)),
  elevation = as.numeric(substr(stations_data, 32, 37)),
  name = trimws(substr(stations_data, 39, 68)),
  stringsAsFactors = FALSE
)

stations_df$country <- NA_character_

# API key for OpenCage
opencage_key <- "dbd2d1729b7a489ca5722d9a5f0d4f02"

# Function to fetch country code
fetch_country_code <- function(lat, lon, api_key) {
  url <- "https://api.opencagedata.com/geocode/v1/json"
  response <- tryCatch(
    GET(url, query = list(
      q = paste(lat, lon, sep = ","),
      key = api_key,
      limit = 1,
      no_annotations = 1
    )),
    error = function(e) NULL
  )
  if (!is.null(response)) {
    response_data <- content(response, "parsed", encoding = "UTF-8")
    if (!is.null(response_data$results) && length(response_data$results) > 0) {
      components <- response_data$results[[1]]$components
      if (!is.null(components$country_code)) {
        return(components$country_code)
      }
    }
  }
  return(NA)
}

# Fetch country codes
for (i in 1:nrow(stations_df)) {
  lat <- stations_df$latitude[i]
  lon <- stations_df$longitude[i]
  country_code <- fetch_country_code(lat, lon, opencage_key)
  stations_df$country[i] <- ifelse(length(country_code) > 0, country_code, NA)
  Sys.sleep(1)
}

# Save the results to a file
write.csv(stations_df, "opencage/opencage-ghcnd-prefix-lookup.csv", row.names = FALSE)
