#!/usr/bin/env bash
find . -maxdepth 1 -type f -name '*.mp4' -print0 | while IFS= read -r -d '' file; do
  echo "Found MP4 file: $file"
done

read -p "Convert to av1_nvenc with pcm audio to edit in Davinci Resolve? (y/n): " confirm
if [ "$confirm" = "y" ]; then

  find . -maxdepth 1 -type f -name '*.mp4' -print0 | while IFS= read -r -d '' file; do
    codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file")

    if [ "$codec" == "h264" ]; then
      output="${file%.mp4}-av1.mp4"
      echo "Converting $file (H.264) to AV1 format as $output"

      ffmpeg -i "$file" -c:v av1_nvenc -cq 30 -c:a pcm_s16le -y "$output"

      echo "Finished converting $file to $output"
    else
      echo "Skipping $file (already in $codec)"
    fi
  done
  echo "All files processed."

else
  echo "Operation cancelled."
fi
