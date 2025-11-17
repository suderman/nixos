{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.printscreen;
  inherit (lib) mkOption types;
  inherit (config.networking) hostName;
  dir = with config.xdg.userDirs; rec {
    home = config.home.homeDirectory;
    screenshots = "${extraConfig.XDG_PICTURES_DIR or "${home}/Pictures"}/Screenshots";
    screencasts = "${extraConfig.XDG_VIDEOS_DIR or "${home}/Videos"}/Screencasts";
    icons = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark/16x16/devices";
    cache = config.xdg.cacheHome;
  };

  printscreen = pkgs.self.mkScript {
    path = with pkgs; [
      ffmpeg
      gawk # awk
      grim # capture image
      hyprpicker # color picker
      libnotify # notify-send
      pngquant # optimize image
      procps # pidof kill
      unstable.satty # annotate image
      slurp # crop screen selection
      wf-recorder # capture video
      wl-clipboard # wl-copy
    ];
    name = "printscreen";
    text = let
      wf = {
        codec =
          if cfg.codec == ""
          then ""
          else "--codec ${cfg.codec}";
        framerate =
          if cfg.framerate > 0
          then "--framerate ${toString cfg.framerate}"
          else "";
        params = toString (lib.mapAttrsToList
          (n: v: "-p ${toString n}=${toString v}")
          cfg.params);
      };
    in
      # bash
      ''
        printscreen_color() {
          hyprpicker -al
          notify-send "$(wl-paste)"
        }

        printscreen_image() {
          # Save location
          local output
          output="${dir.screenshots}/${hostName}-$(date '+%Y%m%d-%H%M%S').png"
          mkdir -p $(dirname $output)

          # Focused display in hyprland
          local display
          display="-o $(hyprctl monitors | awk '/Monitor/{mon=$2} /focused: yes/{print mon}')"

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
          wl-copy --type image/png <"$output"

          # Notification when done
          notify-send 'Screenshot' "$output" -i "${dir.icons}/camera.svg"
        }

        printscreen_video() {

          # Toggle capture off (if recording)
          if [[ "$(printscreen_status)" == "video" ]]; then
            pkill --signal SIGINT wf-recorder
            while pgrep wf-recorder >/dev/null; do sleep 0.1; done
            wl-copy<${dir.cache}/recorder
            rm -f ${dir.cache}/recorder
            notify-send 'Ended capture' "$(wl-paste)"  -i "${dir.icons}/camera.svg"
            pkill -RTMIN+8 waybar # toggle indicator

          # Toggle capture on
          else

            # Save location
            output="${dir.screencasts}/${hostName}-$(date '+%Y%m%d-%H%M%S').mp4"
            mkdir -p $(dirname $output)
            echo "$output">${dir.cache}/recorder

            # Record screen
            coords="$(slurp)"
            if [[ -n "$coords" ]]; then
              wf-recorder --geometry "$coords" ${wf.framerate} ${wf.codec} ${wf.params} -a -f "$output" &
              pkill -RTMIN+8 waybar # toggle indicator
            fi
          fi
        }

        printscreen_status() {
          if [ -n "$(pgrep wf-recorder)" ]; then
            echo "video"
          else
            echo ""
          fi
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
          status | s)
            printscreen_status
            ;;
          help | *)
            echo "Usage: printscreen ACTION"
            echo
            echo "  color"
            echo "  image"
            echo "  video"
            echo "  status"
            echo "  help"
            ;;
        esac
      '';
  };
in {
  options.programs.printscreen = {
    enable = mkOption {
      type = types.bool;
      default = true;
      example = false;
    };
    codec = mkOption {
      type = types.str;
      default = "";
      example = "libsvtav1";
    };
    params = mkOption {
      type = types.attrs;
      default = {};
      example = {
        preset = 5;
        crf = 45;
      };
    };
    framerate = mkOption {
      type = types.int;
      default = 0;
      example = 20;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [printscreen];

    wayland.windowManager.hyprland.settings = {
      bind = [
        ", print, exec, printscreen image"
        "alt, print, exec, printscreen video"
        "shift, print, exec, printscreen video"
        "ctrl, print, exec, printscreen color"
      ];
      windowrule = [
        "fullscreen, class:com.gabm.satty"
        "float, class:com.gabm.satty"
      ];
    };

    xdg.configFile."satty/config.toml" = let
      settings = {
        general = {
          fullscreen = true;
          early-exit = true;
          corner-roundness = 12;
          initial-tool = "crop";
          copy-command = "${pkgs.wl-clipboard}/bin/wl-copy";
          annotation-size-factor = 1;
          output-filename = "${dir.screenshots}/${hostName}-%Y%m%d-%H%M%S.png";
          save-after-copy = false;
          default-hide-toolbars = false;
          primary-highlighter = "block"; # block, freehand
          disable-notifications = false;
          actions-on-right-click = []; # save-to-clipboard, save-to-file, exit
          actions-on-enter = ["save-to-file" "exit"]; # save-to-clipboard, save-to-file, exit
          actions-on-escape = ["exit"]; # save-to-clipboard, save-to-file, exit
          no-window-decoration = true;
        };
        # keybinds = {
        #   pointer = "p"; crop = "c"; brush = "b"; line = "i"; arrow = "z"; rectangle = "r";
        #   ellipse = "e"; text = "t"; marker = "m"; blur = "u"; highlight = "g";
        # };
        font = {
          family = "Roboto";
          style = "Regular";
        };
        color-palette.palette = [
          "#dc143c"
          "#00ffff"
          "#a52a2a"
          "#ff1493"
          "#ffd700"
          "#008000"
        ];
      };
    in {
      source = (pkgs.formats.toml {}).generate "satty-config.toml" settings;
    };
  };
}
