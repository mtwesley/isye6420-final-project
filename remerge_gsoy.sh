#!/bin/bash

input_dir="noaa_ncei/gsoy-merged"
output_dir="noaa_ncei/gsoy-remerged"
prefix_file="noaa_ncei/prefix_to_country_code.csv"

# Ensure output directory exists
mkdir -p "$output_dir"

# Read prefix mappings into an associative array
declare -A prefix_map
while IFS=, read -r prefix country_code; do
  prefix_map["$prefix"]="$country_code"
done <"$prefix_file"

# Process each file in the input directory
for input_file in "$input_dir"/*.csv; do
  file_name=$(basename "$input_file" .csv)

  # Check if the file name matches a prefix in the mapping
  if [[ -v prefix_map["$file_name"] ]]; then
    # File needs renaming logic
    country_code=${prefix_map["$file_name"]}
    output_file="$output_dir/$country_code.csv"
    temp_file=$(mktemp)

    # Replace the first column (prefix) with the correct country code
    awk -v new_code="$country_code" 'NR == 1 {print; next} {sub($1, new_code); print}' "$input_file" >"$temp_file"

    # Append to output file, adding header row if necessary
    if [[ -f "$output_file" ]]; then
      # Append data without header
      tail -n +2 "$temp_file" >>"$output_file"
    else
      # Add header and data
      mv "$temp_file" "$output_file"
    fi
    rm -f "$temp_file"
  else
    # File name does not match a prefix; copy it as-is
    output_file="$output_dir/$file_name.csv"
    if [[ -f "$output_file" ]]; then
      # Append data without header
      tail -n +2 "$input_file" >>"$output_file"
    else
      # Add header and data
      cp "$input_file" "$output_file"
    fi
  fi
done

echo "Processing complete. Files are in $output_dir"
