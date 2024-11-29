#!/bin/bash

# Enable verbose logging
set -e
set -o pipefail
set -x

# Set the input and output directories
input_dir="gsom-latest"
output_dir="gsom-merged"
mkdir -p "$output_dir"

# Temporary file to store the file list
file_list="gsom_list.txt"

echo "Generating the list of CSV files..."
find "$input_dir" -type f -name "*.csv" >"$file_list"
echo "File list saved to $file_list."

# Step 1: Extract unique country codes from the file list
echo "Extracting country codes from file names..."
country_codes=$(awk -F '/' '{print substr($NF, 1, 2)}' "$file_list" | sort | uniq)
echo "Found country codes: $country_codes"

# Step 2: Process each country code
for country_code in $country_codes; do
  echo "Processing country code: $country_code"

  # Find all files for the current country from the file list
  grep "/${country_code}" "$file_list" >"country_files.txt"
  echo "Files for $country_code saved to country_files.txt."

  # Initialize the output country file
  country_output="$output_dir/${country_code}.csv"
  >"$country_output" # Empty the file if it exists
  echo "Initialized country output file: $country_output"

  # Merge files for the current country
  header_written=false
  while IFS= read -r file; do
    echo "Merging file: $file"

    if [ "$header_written" = false ]; then
      # Write the header row from the first file
      head -n 1 "$file" >>"$country_output"
      echo "Header written from: $file"
      header_written=true
    fi
    # Append the rest of the data (skip header row)
    tail -n +2 "$file" >>"$country_output"
    echo "Data appended from: $file"
  done <"country_files.txt"

  # Step 3: Sort the merged file by the date column (assumed to be the second column)
  sorted_output="$output_dir/${country_code}_sorted.csv"
  echo "Sorting merged data by date and saving to: $sorted_output"
  sort -t ',' -k2 "$country_output" >"$sorted_output"
  echo "Sorting complete for $country_code"

  # Clean up temporary country-specific file list
  rm -f "country_files.txt"
done

# Clean up the main file list
rm -f "$file_list"

echo "File processing completed successfully!"
