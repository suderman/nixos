{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ 
      gnome.nautilus
    ];

    # keyboard shortcuts
    services.keyd.applications = {
      org-gnome-nautilus = {
        "alt.enter" = "f2";
        "alt.r" = "f2";
        "alt.i" = "C-i";
        "meta.t" = "C-t";
        "meta.n" = "C-n";
      };
    };

  };
}
