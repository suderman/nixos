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
        "meta.r" = "f2";
        "alt.i" = "C-i";
        "alt.h" = "A-left";
        "alt.j" = "A-down";
        "alt.k" = "A-up";
        "alt.l" = "A-left";
        "meta.t" = "C-t"; # new tab
        "meta.n" = "C-n"; # new window
        "meta+shift.n" = "C-S-n"; # new folder
        "meta.[" = "C-pageup"; # prev tab
        "meta.]" = "C-pagedown"; # next tab
        "meta.c" = "C-c";
        "meta.x" = "C-x";
        "meta.v" = "C-v";

      };
    };

  };
}
