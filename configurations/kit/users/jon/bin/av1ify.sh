#!/usr/bin/env bash

for file in *.mp4; do
  codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file")

  if [ "$codec" == "h264" ]; then
    output="${file%.mp4}-av1.mp4"
    echo "Converting $file (H.264) to AV1 format as $output"

    ffmpeg -i "$file" -c:v av1_nvenc -cq 30 -c:a pcm_s16le "$output"

    echo "Finished converting $file to $output"
  else
    echo "Skipping $file (already in $codec)"
  fi
done

echo "All files processed."
