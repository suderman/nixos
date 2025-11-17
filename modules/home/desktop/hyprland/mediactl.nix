{pkgs, ...}: let
  mediactl = pkgs.self.mkScript {
    name = "mediactl";
    path = with pkgs; [
      brightnessctl
      gnugrep
      libnotify
      mako
      mpc-cli
      playerctl
    ];
    text =
      # bash
      ''
        mediactl_help() {
            echo "Usage: mediactl ACTION"
            echo
            echo "  down"
            echo "  up"
            echo "  mute"
            echo "  mic"
            echo "  play"
            echo "  prev"
            echo "  next"
            echo "  rewind"
            echo "  forward"
            echo "  shift"
            echo "  dark"
            echo "  light"
            echo "  sunset"
            echo "  help"
        }

        mediactl_down() {
          volumectl -d -pb down
        }

        mediactl_up() {
          volumectl -d -pbu up
        }

        mediactl_mute() {
          volumectl -d -a toggle-mute
        }

        mediactl_mic() {
          volumectl -d -am toggle-mute
        }

        mediactl_play() {
          playerctl play-pause
        }

        mediactl_prev() {
          playerctl previous
        }

        mediactl_next() {
          playerctl next
        }

        mediactl_rewind() {
          if [[ "$(playerctl -l | head -n1)" == "mpd" ]]; then
            mpc seek -15
          else
            mediactl_prev
          fi
        }

        mediactl_forward() {
          if [[ "$(playerctl -l | head -n1)" == "mpd" ]]; then
            mpc seek +30
          else
            mediactl_next
          fi
        }

        mediactl_shift() {
          if [[ "$(playerctl -l | wc -l)" != "1" ]]; then
            playerctld shift
            makoctl dismiss
            notify-send "Current Player" "$(playerctl -l | head -n1)"
          fi
        }

        mediactl_show_brightness() {
          gamma="$(hyprctl hyprsunset gamma)"
          if [ "''${gamma%.*}" -le 33 ]; then
            image='brightness_low_dark'
          elif [ "''${gamma%.*}" -le 66 ]; then
            image='brightness_medium_dark'
          else
            image='brightness_high_dark'
          fi
          progress=$(echo "$gamma" | awk '{ printf "%.2f", $1 / 100 }')
          avizo-client --image-resource="$image" --progress="$progress"
        }

        mediactl_dark() {
          if brightnessctl --list 2>/dev/null | grep -q "backlight"; then
            lightctl -d down
          else
            hyprctl hyprsunset gamma -5
            mediactl_show_brightness
          fi
        }

        mediactl_light() {
          if brightnessctl --list 2>/dev/null | grep -q "backlight"; then
            lightctl -d up
          else
            hyprctl hyprsunset gamma +5
            mediactl_show_brightness
          fi
        }

        mediactl_sunset() {
          if [[ "$(hyprctl hyprsunset temperature)" != "6000" ]]; then
            hyprctl hyprsunset temperature 6000 # normal color
          else
            hyprctl hyprsunset temperature 2500 # sunset color
          fi
        }

        cmd="''${1-help}"
        case "$cmd" in
          down | up | mute | mic | play | prev | next | rewind | forward | shift | light | dark | sunset)
            mediactl_$cmd
            ;;
          help | *)
            mediactl_help
        esac

      '';
  };
in {
  home.packages = [mediactl];

  services.playerctld = {
    enable = true; # playerctl playerctld
  };

  services.avizo = {
    enable = true; # lightctl volumectl
    settings = {
      # https://github.com/misterdanb/avizo/blob/master/config.ini
      default = {
        time = 1.0;
        y-offset = 0.5;
        fade-in = 0.1;
        fade-out = 0.2;
        padding = 10;
      };
    };
  };

  services.hyprsunset = {
    enable = true; # hyprctl hyprsunset
    transitions = {
      sunrise.calendar = "*-*-* 06:00:00";
      sunset.calendar = "*-*-* 20:00:00";
      sunset.requests = [
        ["temperature 3500"]
        ["gamma 0.8"]
      ];
    };
  };

  wayland.windowManager.hyprland.settings = {
    binde = [
      # Screen brightness
      ", XF86MonBrightnessUp, exec, mediactl light"
      ", XF86MonBrightnessDown, exec, mediactl dark"

      # Volume control
      ", XF86AudioRaiseVolume, exec, mediactl up"
      ", XF86AudioLowerVolume, exec, mediactl down"
    ];

    bind = [
      # Mute toggle
      ", XF86AudioMute, exec, mediactl mute"
      # ", XF86AudioMicMute, exec, mediactl mic"

      # Screen color filter
      "shift, XF86MonBrightnessUp, exec, mediactl sunset"
      "shift, XF86MonBrightnessDown, exec, mediactl sunset"
      ", XF86AudioMicMute, exec, mediactl sunset"
    ];

    bindl = [
      # play and pause active player
      ", XF86AudioPlay,  exec, mediactl play"

      # shift+playpause change active player
      "shift, XF86AudioPlay, exec, mediactl shift"

      # Attempt rewind, fallback on previous track (same for shift volup)
      ", XF86AudioPrev,  exec, mediactl rewind"
      "shift, XF86AudioLowerVolume, exec, mediactl rewind"

      # Attempt to fast forward, fall on next track (same for shift voldown)
      ", XF86AudioNext,  exec, mediactl forward"
      "shift, XF86AudioRaiseVolume, exec, mediactl forward"
    ];

    bindlo = [
      # Hold key to skip to previous track
      ", XF86AudioPrev,  exec, mediactl prev"
      "shift, XF86AudioLowerVolume, exec, mediactl prev"

      # Hold key to skip to next track
      ", XF86AudioNext,  exec, mediactl next"
      "shift, XF86AudioRaiseVolume, exec, mediactl next"
    ];
  };
}
