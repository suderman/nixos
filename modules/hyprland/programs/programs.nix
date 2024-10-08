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

    # Check modules directory for extra configuration
    programs = {
      kitty.enable = true; # term
      firefox.enable = true; # web browser
      chromium.enable = true; # alt browser
      yazi.enable = true; # file manager tui
      gimp.enable = true; # image editor
      bluebubbles.enable = true; # ios chat
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
      wf-recorder # screen recording
      grim # taking screenshots
      slurp # selecting a region to screenshot
      xorg.xeyes # confirm xwayland
      mpv

      font-awesome # icon font
      jetbrains-mono # mono font

      tdesktop # family chat
      slack # work chat

      neovide # text editor
      lapce # text editor
      inkscape # vector editor
      libreoffice # documents & spreadsheets

      nemo-with-extensions # file manager gui
      junction # browser chooser

      quickemu # virtual machines
      qalculate-gtk # calculator
      newsflash # rss reader
      tauon # mp3 player (and jellyfin client)

      pulseaudio # pactl
      pavucontrol # sound control gui
      ncpamixer # sound control tui

    ];

  };

}
