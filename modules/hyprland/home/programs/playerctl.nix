{ config, lib, pkgs, ... }: let 

  #          KEY | ACTION
  # ------------ | ------------------------------
  #   VolumeDown | Decrease Volume
  # ⇧ VolumeDown | Rewind mpd or Previous Track
  #
  #     VolumeUp | Increase Volume
  #   ⇧ VolumeUp | Fast-forward mpd or Next Track
  #
  #         Mute | Toggle Speaker
  #       ⇧ Mute | Toggle Microphone
  #
  #   PauseBreak | Toggle Playback
  # ⌥ PauseBreak | Toggle Playback on ALL players
  # ⇧ PauseBreak | Shift current player
  #
  #        Media | Shift current speaker
  #      ⇧ Media | Toggle Bluetooth connection

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf getExe mkShellScript;

  # If more than one player is detected, shift to the next one and notify
  shiftPlayer = mkShellScript {
    inputs = with pkgs; [ playerctl libnotify mako ]; 
    text = ''
      if [[ "$(playerctl -l | wc -l)" != "1" ]]; then
        playerctld shift
        makoctl dismiss
        notify-send "Current Player" "$(playerctl -l | head -n1)"
      fi
    '';
  };

  rewindOrPrevious = mkShellScript {
    inputs = with pkgs; [ playerctl mpc-cli ]; 
    text = ''
      if [[ "$(playerctl -l | head -n1)" == "mpd" ]]; then
        mpc seek -15
      else
        playerctl previous
      fi
    '';
  };

  fastForwardOrNext = mkShellScript {
    inputs = with pkgs; [ playerctl mpc-cli ]; 
    text = ''
      if [[ "$(playerctl -l | head -n1)" == "mpd" ]]; then
        mpc seek +30
      else
        playerctl next
      fi
    '';
  };

in {

  config = mkIf cfg.enable {

    services.playerctld.enable = true; 
    home.packages = [ pkgs.playerctl ];

    wayland.windowManager.hyprland.settings = {
      bindl = [

        # play and pause active player
        ", XF86AudioPlay,  exec, playerctl play-pause"
        ", XF86AudioStop,  exec, playerctl pause"
        ", XF86AudioPause, exec, playerctl pause"

        # alt controls all players at once
        "alt, XF86AudioPlay, exec, playerctl --all-players play-pause"

        # shift+playpause change active player
        "shift, XF86AudioPlay, exec, ${shiftPlayer}"

        # attempt seek, fallback on skip
        ", XF86AudioPrev,  exec, ${rewindOrPrevious}"
        ", XF86AudioNext,  exec, ${fastForwardOrNext}"

        # always skip tracks with alt 
        "alt, XF86AudioPrev,  exec, playerctl previous"
        "alt, XF86AudioNext,  exec, playerctl next"

      ];

    };

  };

}
