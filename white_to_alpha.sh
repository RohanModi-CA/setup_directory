#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 input.jpeg"
    exit 1
fi

# Input file
input_file="$1"
# Output file (same name with _transparent suffix)
output_file="${input_file%.*}_tp.png"

# Convert white to transparent
convert "$input_file" \
    \( \
        -clone 0 \
        -fill white \
        -colorize 100 \
    \) \
    \( \
        -clone 0,1 \
        -compose difference \
        -composite \
        -separate \
        +channel \
        -evaluate-sequence max \
        -auto-level \
    \) \
    -delete 1 \
    -alpha off \
    -compose over \
    -compose copy_opacity \
    -composite \
    -fuzz 20% \
    -transparent white \
    "$output_file"

echo "Converted $input_file to transparent version: $output_file"
