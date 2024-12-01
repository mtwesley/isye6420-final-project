#!/bin/bash

# Define the URL for the GHCND stations file
FILE_URL="https://www.ncei.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt"

# Define the output file for filtered stations
OUTPUT_FILE="noaa_ncei/ghcnd-stations-filtered.txt"

# Download the GHCND stations file
echo "Downloading ghcnd-stations.txt..."
curl -o "noaa_ncei/ghcnd-stations.txt" $FILE_URL

# Define the regex pattern for grep
PATTERN="^(AJ|AY|BC|BK|BP|BU|CE|CJ|CQ|CS|CT|DA|DR|EI|EN|EU|EZ|FG|FP|FS|HO|IC|IV|JA|JN|JQ|JU|KS|KT|KU|LE|LG|LH|LO|MB|MI|MJ|NH|NN|NS|PC|PO|PP|RI|RM|RP|RQ|SF|SP|SU|SW|TE|TI|TS|TU|TX|UC|UK|UP|UV|VM|VQ|WA|WI|WQ|WZ|ZI)"

# Filter the file for lines starting with the specified prefixes
echo "Filtering stations with specified prefixes..."
grep -E "$PATTERN" ghcnd-stations.txt >$OUTPUT_FILE

# Confirm completion
echo "Filtered stations saved to $OUTPUT_FILE"
