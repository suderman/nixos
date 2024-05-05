{ config, lib, pkgs, this, ... }: {

  modules.hyprland.preSettings = {
    monitor = [ 
      ", 2560x1440@60.00Hz, 0x0, 1"
    ];
  };

  modules.hyprland.nvidia = true;
  modules.hyprland.settings = {

    # # Execute your favorite apps at launch
    # exec-once = [ ];
    #
    # general = {
    #   gaps_in = 4;
    #   gaps_out = 8;
    #   border_size = 2;
    # };
    #
    # misc = {
    #   disable_hyprland_logo = false;
    #   disable_splash_rendering = false;
    #   swallow_regex = "^(Alacritty|kitty|footclient)$";
    #   focus_on_activate = true;
    #   # suppress_portal_warnings = true;
    # };
    #
    # decoration = {
    #   rounding = 10;
    #   dim_inactive = false;
    #   dim_strength = 0.1;
    # };

    bind = [ ];
    binde = [ ];
    bindm = [ ];

  };

}
