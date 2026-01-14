#!/usr/bin/env bash

#############################################
#
# Convert Unix time timestamps in application 
# log files to human readable format
#
#  Usage:
#  
#  ./convert-epoch.sh input.log
#
#############################################

set -euo pipefail

input_file="$1"
output_file="${input_file}.converted"

while read -r line; do
  epoch=${line%% *}                     # first field
  remainder_of_line=${line#* }          # remainder of line

  human_readable_date=$(date -d "@${epoch%.*}" "+%Y-%m-%d %H:%M:%S")

  printf '%s %s\n' "$human_readable_date" "$remainder_of_line"
done < "$input_file" > "$output_file"
