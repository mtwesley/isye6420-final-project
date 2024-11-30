#!/bin/bash

# Directories and output file
input_dir="gsoy-aggregated"
output_file="gsoy-aggregated-all.csv"

# Check if input directory exists
if [ ! -d "$input_dir" ]; then
  echo "Input directory does not exist: $input_dir"
  exit 1
fi

# Initialize variables
header=""
is_first_file=true

# Clear or create the output file
>"$output_file"

# Iterate through each CSV file in the directory
for file in "$input_dir"/*.csv; do
  if [ -f "$file" ]; then
    echo "Processing file: $file"

    # Read the header of the current file
    current_header=$(head -n 1 "$file")

    # If it's the first file, write the header and data to the output
    if [ "$is_first_file" = true ]; then
      echo "$current_header" >"$output_file"
      tail -n +2 "$file" >>"$output_file"
      header="$current_header"
      is_first_file=false
    else
      # For subsequent files, check if the header matches the first file's header
      if [ "$current_header" != "$header" ]; then
        echo "Header mismatch in file: $file"
        echo "Expected: $header"
        echo "Found: $current_header"
        exit 1
      fi
      # Append data without header
      tail -n +2 "$file" >>"$output_file"
    fi
  else
    echo "No CSV files found in directory: $input_dir"
  fi
done

echo "All files merged into: $output_file"
