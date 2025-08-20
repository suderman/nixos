{perSystem, ...}:
perSystem.self.mkScript {
  name = "lsdisk";
  text =
    # bash
    ''
      # Color definitions
      HEADER_COLOR='\033[1;36m'    # Bright cyan
      SEPARATOR_COLOR='\033[0;34m' # Blue
      RESET='\033[0m'              # Reset color

      # Function to get device ID for a given device
      get_device_id() {
          local device="$1"
          local device_path="/dev/''${device}"

          # Find the device ID by looking in /dev/disk/by-id/
          for id_link in /dev/disk/by-id/*; do
              if [ -L "$id_link" ] && [ "$(readlink -f "$id_link")" = "$device_path" ]; then
                  # Get just the filename (ID) without the path
                  basename "$id_link"
                  return
              fi
          done

          # If no ID found, return empty string
          echo ""
      }

      # Print header with colors and better symbols
      echo -e "''${HEADER_COLOR}┌─────────────────┬─────────┬─────────┬────────────────────────────────────────────────────┐''${RESET}"
      printf "''${HEADER_COLOR}│ %-15s │ %-7s │ %-7s │ %-50s │''${RESET}\n" "NAME" "SIZE" "FSTYPE" "MOUNTPOINT / DEVICE-ID"
      echo -e "''${SEPARATOR_COLOR}├─────────────────┼─────────┼─────────┼────────────────────────────────────────────────────┤''${RESET}"

      # Process lsblk output line by line
      lsblk -o NAME,SIZE,MOUNTPOINTS,FSTYPE --noheadings | while IFS= read -r line; do
          # Parse the line carefully to handle spaces in mount points
          name=$(echo "$line" | awk '{print $1}')
          size=$(echo "$line" | awk '{print $2}')

          # Extract device name without tree characters for ID lookup and type detection
          device_name=$(echo "$name" | sed 's/[├─└│ ]//g')

          # Get the remaining part after name and size
          remaining=$(echo "$line" | sed -E 's/^[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]*//')

          # Parse mountpoint and fstype from remaining text
          mountpoint=""
          fstype=""

          if [[ -n "$remaining" ]]; then
              # If the remaining text contains a known filesystem type, split accordingly
              if [[ "$remaining" =~ ^(.*)[[:space:]]+(ext[234]|xfs|btrfs|ntfs|vfat|swap|fat32|exfat)$ ]]; then
                  mountpoint="''${BASH_REMATCH[1]}"
                  fstype="''${BASH_REMATCH[2]}"
              elif [[ "$remaining" =~ ^(ext[234]|xfs|btrfs|ntfs|vfat|swap|fat32|exfat)[[:space:]]*(.*)$ ]]; then
                  fstype="''${BASH_REMATCH[1]}"
                  mountpoint="''${BASH_REMATCH[2]}"
              elif [[ "$remaining" =~ ^(/[^[:space:]]*|\\[SWAP\\])[[:space:]]+(.*)$ ]]; then
                  mountpoint="''${BASH_REMATCH[1]}"
                  fstype="''${BASH_REMATCH[2]}"
              else
                  # If we can't parse it cleanly, assume it's all mountpoint
                  mountpoint="$remaining"
              fi
          fi

          # Clean up mountpoint and fstype
          mountpoint=$(echo "$mountpoint" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          fstype=$(echo "$fstype" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

          # Truncate mountpoint if too long
          [[ ''${#mountpoint} -gt 12 ]] && mountpoint="''${mountpoint:0:9}..."

          # Get device ID only for main devices (not partitions)
          # For partitions, use mountpoint; for main devices, use device ID
          last_column=""
          if [[ "$device_name" =~ ^(sd[a-z]|nvme[0-9]+n[0-9]+|mmcblk[0-9]+|vd[a-z]|hd[a-z])$ ]]; then
              # This is a main device, show device ID
              last_column=$(get_device_id "$device_name")
          else
              # This is a partition, show mountpoint
              last_column="$mountpoint"
          fi

          # Calculate the visual length of the name (accounting for tree characters)
          name_visual_length=$(echo -n "$name" | wc -m)
          padding_needed=$((15 - name_visual_length))

          # Create padding string
          padding=$(printf "%*s" $padding_needed "")

          # Print formatted line with manual padding
          printf "│ %s%s │ %-7s │ %-7s │ %-50s │\n" "$name" "$padding" "$size" "$fstype" "$last_column"
      done

      # Print bottom border
      echo -e "''${SEPARATOR_COLOR}└─────────────────┴─────────┴─────────┴────────────────────────────────────────────────────┘''${RESET}"
    '';
}
