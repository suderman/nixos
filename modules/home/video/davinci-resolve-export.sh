#!/usr/bin/env bash

# Check if input file is provided
if [ -z "${1-}" ]; then
    echo "Usage: $0 <input_file.mov>"
    exit 1
fi

file="$1"
output="${file%.*}-final.mp4"

echo "Converting $file to H.264 (x264) with AAC audio as $output"

# Convert to x264 video codec and AAC audio codec
ffmpeg -i "$file" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 192k "$output"

echo "Finished conversion: $output"
