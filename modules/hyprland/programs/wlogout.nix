# powerkey
{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) getExe mkIf mkShellScript;

  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
  systemctl = "${pkgs.systemd}/bin/systemctl";

  # Wrapper script for formatting and prevent multiple instances
  powerkey = mkShellScript { 
    name = "powerkey"; 
    inputs = with pkgs; [ procps wlogout ];
    text = ''
      if ! $(pidof -q wlogout >/dev/null); then
        wlogout -b 2 -m 300 -L 500 -R 500
      fi
    '';
  };

in {

  config = mkIf cfg.enable {

    # Add wrapper to path
    home.packages = [ powerkey ]; 

    # Run wlogout via powerkey button press
    wayland.windowManager.hyprland.settings = {
      bind = [ ", XF86PowerOff, exec, ${getExe powerkey}" ];
    };

    # Configure grid of 4 buttons
    programs.wlogout = {
      enable = true;
      layout = with pkgs; [
        {
          label = "lock";
          action = "${hyprlock} --immediate";
          text = "Lock";
          keybind = "l";
        }
        {
          label = "logout";
          action = "${hyprctl} dispatch exit 0";
          text = "Logout";
          keybind = "q";
        }
        {
          label = "shutdown";
          action = "${systemctl} poweroff";
          text = "Shutdown";
          keybind = "s";
        }
        {
          label = "reboot";
          action = "${systemctl} reboot";
          text = "Reboot";
          keybind = "r";
          circular = true;
        }
      ];

    };

  };

}
