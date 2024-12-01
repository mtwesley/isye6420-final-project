#!/bin/bash

# File containing station data
input_file="noaa_ncei/ghcnd-stations-filtered.txt"

# Output file
output_file="noaa_ncei/ghcnd-stations-filtered-unique.txt"

# Prefixes to filter (space-separated list)
prefixes=("AJ" "AY" "BC" "BK" "BP" "BU" "CE" "CJ" "CQ" "CS" "CT" "DA"
  "DR" "EI" "EN" "EU" "EZ" "FG" "FP" "FS" "HO" "IC" "IV" "JA"
  "JN" "JQ" "JU" "KS" "KT" "KU" "LE" "LG" "LH" "LO" "MB" "MI"
  "MJ" "NH" "NN" "NS" "PC" "PO" "PP" "RI" "RM" "RP" "RQ" "SF"
  "SP" "SU" "SW" "TE" "TI" "TS" "TU" "TX" "UC" "UK" "UP" "UV"
  "VM" "VQ" "WA" "WI" "WQ" "WZ" "ZI")

# Build the grep pattern
pattern=$(printf "^%s|" "${prefixes[@]}")
pattern=${pattern%|} # Remove trailing pipe '|'

# Filter the file by matching prefixes
grep -E "$pattern" "$input_file" >"$output_file"

# Report the result
echo "Filtered stations saved to $output_file"
