{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ 
      gnome.nautilus
    ];

    # keyboard shortcuts
    services.keyd.windows = {
      org-gnome-nautilus = {

        "alt.enter" = "f2";
        "alt.r" = "f2";
        "super.r" = "f2";
        "alt.i" = "C-i";
        "alt.h" = "A-left";
        "alt.j" = "A-down";
        "alt.k" = "A-up";
        "alt.l" = "A-left";
        "super.o" = "C-l"; # location bar
        "super.t" = "C-t"; # new tab
        "super.n" = "C-n"; # new window
        "super.w" = "C-w"; # close tab
        "super+shift.n" = "C-S-n"; # new folder
        "super.[" = "C-pageup"; # prev tab
        "super.]" = "C-pagedown"; # next tab
        "super.c" = "C-c";
        "super.x" = "C-x";
        "super.v" = "C-v";

      };
    };

  };
}
