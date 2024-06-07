{ config, lib, pkgs, this, ... }: {

  config.wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = [ # embedded display (laptop)
        "eDP-1, 2256x1504@59.9990001, 500x1440, 1.333333"
      ];
    };
  };

  # modules.hyprland.settings = {
  #
  #   # # Execute your favorite apps at launch
  #   # exec-once = [ "waybar" ];
  #   #
  #   # general = {
  #   #   gaps_in = 4;
  #   #   gaps_out = 8;
  #   #   border_size = 2;
  #   # };
  #   #
  #   # misc = {
  #   #   disable_hyprland_logo = false;
  #   #   disable_splash_rendering = false;
  #   #   swallow_regex = "^(Alacritty|kitty|footclient)$";
  #   #   focus_on_activate = true;
  #   #   # suppress_portal_warnings = true;
  #   # };
  #   #
  #   # decoration = {
  #   #   rounding = 10;
  #   #   dim_inactive = false;
  #   #   dim_strength = 0.1;
  #   # };
  #
  #   bind = [ "SUPER SHIFT ALT, m, exec, zwift" ];
  #   binde = [ ];
  #   bindm = [ ];
  #
  # };

}
