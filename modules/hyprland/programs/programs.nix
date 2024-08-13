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
      kitty.enable = true;
      chromium.enable = true;
    };

    # Add these to my path
    home.packages = with pkgs; [ 
      bounce # defined above
      swww # wallpaper
      brightnessctl
      font-awesome
      wl-clipboard # copying and pasting
      hyprpicker  # color picker
      hyprcursor
      wf-recorder # screen recording
      grim # taking screenshots
      slurp # selecting a region to screenshot
      pulseaudio
      xorg.xeyes # confirm xwayland
      nemo-with-extensions
      mpv
    ];

  };

}
