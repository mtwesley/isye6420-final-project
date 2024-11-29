#!/bin/bash

# Enable verbose logging
set -e  # Exit on error
set -o pipefail  # Ensure pipes fail properly
set -x  # Enable command tracing (verbose mode)

# Set the input and output directories
input_dir="gsom-latest"
output_dir="gsom-merged"
mkdir -p "$output_dir"

echo "Starting the file processing script..."

# Step 1: List all files and extract unique country codes
echo "Listing all files in $input_dir..."
file_list=$(ls "$input_dir"/*.csv)
country_codes=$(ls "$input_dir" | awk -F '/' '{print substr($NF, 1, 2)}' | sort | uniq)

echo "Found country codes: $country_codes"

# Step 2: Process each country code
for country_code in $country_codes; do
    echo "Processing country code: $country_code"

    # Find all files for the current country
    country_files=$(ls "$input_dir" | grep "^$country_code")
    echo "Files for $country_code: $country_files"

    # Initialize the output country file
    country_output="$output_dir/${country_code}.csv"
    > "$country_output"  # Empty the file if it exists
    echo "Initialized country output file: $country_output"

    # Merge files for the current country
    header_written=false
    for file in $country_files; do
        input_file="$input_dir/$file"
        echo "Merging file: $input_file"

        if [ "$header_written" = false ]; then
            # Write the header row from the first file
            head -n 1 "$input_file" >> "$country_output"
            echo "Header written from: $input_file"
            header_written=true
        fi
        # Append the rest of the data (skip header row)
        tail -n +2 "$input_file" >> "$country_output"
        echo "Data appended from: $input_file"
    done

    # Step 3: Sort the merged file by the date column (assumed to be the second column)
    sorted_output="$output_dir/${country_code}_sorted.csv"
    echo "Sorting merged data by date and saving to: $sorted_output"
    sort -t ',' -k2 "$country_output" > "$sorted_output"
    echo "Sorting complete for $country_code"

done

echo "File processing completed successfully!"