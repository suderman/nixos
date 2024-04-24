{ config, lib, pkgs, this, ... }: {

  modules.hyprland.preSettings = {
    monitor = [ ];
  };

  modules.hyprland.settings = {

    # Execute your favorite apps at launch
    exec-once = [ "waybar" ];

    general = {
      gaps_in = 4;
      gaps_out = 8;
      border_size = 2;
    };

    misc = {
      disable_hyprland_logo = false;
      disable_splash_rendering = false;
      swallow_regex = "^(Alacritty|kitty|footclient)$";
      focus_on_activate = true;
      # suppress_portal_warnings = true;
    };

    decoration = {
      rounding = 10;
      dim_inactive = false;
      dim_strength = 0.1;
      dim_special = 0;
    };

    bind = [ "SUPER SHIFT, m, exec, zwift" ];
    binde = [ ];
    bindm = [ ];

    env = [
      "LIBVA_DRIVER_NAME,nvidia"
      "XDG_SESSION_TYPE,wayland"
      "GBM_BACKEND,nvidia-drm"
      "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      "WLR_NO_HARDWARE_CURSORS,1"
    ];

  };

}
