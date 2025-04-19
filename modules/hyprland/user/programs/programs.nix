{ config, lib, pkgs, ... }: let

  inherit (lib) concatStringsSep ls mkIf mkShellScript;

  # Ensure portals and other systemd user services are running
  # https://wiki.hyprland.org/Useful-Utilities/xdg-desktop-portal-hyprland/
  bounce = mkShellScript {
    inputs = with pkgs; [ systemd ]; name = "bounce"; text = let 
      restart = name: "sleep 1 && systemctl --user stop ${name} && systemctl --user start ${name}";
    in concatStringsSep "\n" [ 

      # Ensure portals and other systemd user services are running
      # https://wiki.hyprland.org/Useful-Utilities/xdg-desktop-portal-hyprland/
      ( restart "xdg-desktop-portal-hyprland" )
      ( restart "xdg-desktop-portal-gtk" )
      ( restart "xdg-desktop-portal" )
      ( restart "hyprland-ready.target" )

    ];
  };

in {

  # Programs and packages required by my Hyprland
  config = mkIf config.wayland.windowManager.hyprland.enable {

    xdg.mime.enable = true;
    xdg.mimeApps = {
      enable = true;
    };

    # Check modules directory for extra configuration
    programs = {
      bluebubbles.enable = true; # ios chat
      chromium.enable = true; # alt browser
      firefox.enable = true; # web browser
      kitty.enable = true; # term
      mpv.enable = true; # media player
      yazi.enable = true; # file manager tui
      zwift.enable = true; # fitness
    };

    # Add these to my path
    home.packages = with pkgs; [ 

      bounce # defined above
      swww # wallpaper
      brightnessctl
      wl-clipboard # copying and pasting
      hyprpicker  # color picker
      hyprcursor
      # wf-recorder # screen recording - broken?
      grim # taking screenshots
      slurp # selecting a region to screenshot
      xorg.xeyes # confirm xwayland

      font-awesome # icon font
      jetbrains-mono # mono font

      tdesktop # family chat
      # slack # work chat

      neovide # text editor
      lapce # text editor
      inkscape # vector editor
      libreoffice # documents & spreadsheets

      nemo-with-extensions # file manager gui
      junction # browser chooser

      # quickemu # virtual machines
      qalculate-gtk # calculator
      newsflash # rss reader
      # tauon # mp3 player (and jellyfin client) FIXME: failed to build, retry later

      pulseaudio # pactl
      pavucontrol # sound control gui
      ncpamixer # sound control tui

    ];

  };

}
