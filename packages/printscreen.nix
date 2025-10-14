{
  pkgs,
  perSystem,
  ...
}:
perSystem.self.mkScript {
  path = with pkgs; [
    coreutils
    ffmpeg
    gawk # awk
    grim # capture image
    hyprpicker # color picker
    inetutils # hostname
    libnotify # notify-send
    pngquant # optimize image
    procps # pidof kill
    slurp # crop screen selection
    wf-recorder # capture video
    wl-clipboard # wl-copy
    perSystem.nixpkgs-unstable.satty # annotate image
  ];
  name = "printscreen";
  text =
    # bash
    ''
      filename() {
        echo "$(hostname)-$(date '+%Y%m%d-%H%M%S')"
      }

      is_hyprland() {
        [[ -n $HYPRLAND_INSTANCE_SIGNATURE ]] && command -v hyprctl &>/dev/null
      }

      is_nvidia() {
        command -v nvidia-smi &>/dev/null
      }

      printscreen_color() {
        if is_hyprland; then
          hyprpicker -al
          notify-send "$(wl-paste)"
        fi
      }

      printscreen_image() {
        # Save location
        output="''${XDG_PICTURES_DIR-$HOME/Pictures}/Screenshots/$(filename).png"
        mkdir -p $(dirname $output)

        # Focused display when using hyprland
        display=""
        if is_hyprland; then
          display="-o $(hyprctl monitors | awk '/Monitor/{mon=$2} /focused: yes/{print mon}')"
        fi

        # Capture display, pipe to satty for cropping/annotations, pipe to pngquant for optimization
        grim $display -t ppm -c - |
          satty --filename - \
                --fullscreen \
                --initial-tool=crop \
                --actions-on-enter=save-to-file,exit \
                --actions-on-escape=exit \
                --output-filename - |
          pngquant --quality=65-80 --speed=1 --strip --output "$output" -

        # Also copy saved file to clipboard
        wl-copy<"$output"

        # Notification when done
        notify-send 'Screenshot' "$output" \
          -i "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark/16x16/devices/camera.svg"
      }

      printscreen_video() {

        # Toggle capture off (if recording)
        if [ -n "$(pgrep wf-recorder)" ]; then
          pkill --signal SIGINT wf-recorder
          wl-copy</tmp/printscreen_video
          rm -f /tmp/printscreen_video
          notify-send 'Ended capture' "$(wl-paste)" \
            -i "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark/16x16/devices/camera.svg"
          exit 0
        fi

        # Save location
        output="''${XDG_VIDEOS_DIR-$HOME/Videos}/Screencasts/$(filename).mp4"
        mkdir -p $(dirname $output)

        # AV1 encoder
        local codec="libsvtav1"
        local params="-p preset=5 -p crf=45 -r 20"

        # NVIDIA RTX 40-series+ supports av1_nvenc
        if is_nvidia; then
          codec="av1_nvenc"
          params="-p preset=p7 -p rc=constqp -p qp=28"
        fi

        # Record screen
        echo "$output">/tmp/printscreen_video
        wf-recorder --geometry "$(slurp)" --codec "$codec" $params -a -f "$output"
      }

      case "''${1-}" in
        color | c)
          printscreen_color
          ;;
        image | i)
          printscreen_image
          ;;
        video | v)
          printscreen_video
          ;;
        help | *)
          echo "Usage: printscreen ACTION"
          echo
          echo "  color"
          echo "  image"
          echo "  video"
          echo "  help"
          ;;
      esac
    '';
}
