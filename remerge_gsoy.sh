#!/bin/bash

input_dir="noaa_ncei/gsoy-merged"
output_dir="noaa_ncei/gsoy-remerged"
prefix_file="noaa_ncei/prefix_to_country_code.csv"
log_file="remerge_log.txt"

# Ensure output directory exists
mkdir -p "$output_dir"

# Create or clear the log file
: >"$log_file"

# Read prefix mappings into a regular array
prefix_map_file=$(mktemp)
while IFS=, read -r prefix country_code; do
  echo "$prefix,$country_code" >>"$prefix_map_file"
done <"$prefix_file"

echo "Starting processing..." | tee -a "$log_file"

# Process each file in the input directory
for input_file in "$input_dir"/*.csv; do
  file_name=$(basename "$input_file" .csv)

  # Check if the file name matches a prefix in the mapping
  country_code=$(grep "^$file_name," "$prefix_map_file" | cut -d, -f2)

  if [[ -n $country_code ]]; then
    echo "Processing file: $file_name.csv -> Mapped to country code: $country_code" | tee -a "$log_file"
    output_file="$output_dir/$country_code.csv"
    temp_file=$(mktemp)

    # Replace the first column (prefix) with the correct country code
    awk -v new_code="$country_code" 'NR == 1 {print; next} {sub($1, new_code); print}' "$input_file" >"$temp_file"

    # Append to output file, adding header row if necessary
    if [[ -f "$output_file" ]]; then
      echo "  Appending to existing file: $country_code.csv" | tee -a "$log_file"
      tail -n +2 "$temp_file" >>"$output_file"
    else
      echo "  Creating new file: $country_code.csv" | tee -a "$log_file"
      mv "$temp_file" "$output_file"
    fi
    rm -f "$temp_file"
  else
    echo "Processing file: $file_name.csv -> No mapping found, copying as-is." | tee -a "$log_file"
    output_file="$output_dir/$file_name.csv"
    if [[ -f "$output_file" ]]; then
      echo "  Appending to existing file: $file_name.csv" | tee -a "$log_file"
      tail -n +2 "$input_file" >>"$output_file"
    else
      echo "  Creating new file: $file_name.csv" | tee -a "$log_file"
      cp "$input_file" "$output_file"
    fi
  fi
done

rm -f "$prefix_map_file"
echo "Processing complete. Logs saved to $log_file." | tee -a "$log_file"
