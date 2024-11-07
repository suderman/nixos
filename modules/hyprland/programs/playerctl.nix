{ config, lib, pkgs, ... }: let 

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

in {

  config = mkIf cfg.enable {

    services.playerctld.enable = true; 
    home.packages = [ pkgs.playerctl ];

    wayland.windowManager.hyprland.settings = {
      bindl = [
        ", XF86AudioPlay,  exec, playerctl play-pause"
        ", XF86AudioStop,  exec, playerctl pause"
        ", XF86AudioPause, exec, playerctl pause"
        ", XF86AudioPrev,  exec, playerctl previous"
        ", XF86AudioNext,  exec, playerctl next"

        # shift+playpause change active player
        "shift, XF86AudioPlay, exec, ${shiftPlayer}"
      ];

    };

  };

}
