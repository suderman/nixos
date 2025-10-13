# Programs and packages required by my Hyprland
{
  lib,
  pkgs,
  flake,
  ...
}: let
  # Ensure portals and other systemd user services are running
  # https://wiki.hyprland.org/Useful-Utilities/xdg-desktop-portal-hyprland/
  bounce = pkgs.self.mkScript {
    path = [pkgs.systemd];
    name = "bounce";
    text = let
      restart = name: "sleep 1 && systemctl --user stop ${name} && systemctl --user start ${name}";
    in
      lib.concatStringsSep "\n" [
        # Ensure portals and other systemd user services are running
        # https://wiki.hyprland.org/Useful-Utilities/xdg-desktop-portal-hyprland/
        (restart "xdg-desktop-portal-hyprland")
        (restart "xdg-desktop-portal-gtk")
        (restart "xdg-desktop-portal")
        (restart "hyprland-ready.target")
      ];
  };
in {
  # Check modules directory for extra configuration
  programs = {
    rofi.enable = true; # launcher
    bluetuith.enable = true; # bluetooth tui
  };

  services = {
    swww.enable = true; # wallpaper
  };

  # Add these to my path
  home.packages = with pkgs; [
    bounce # defined above
    brightnessctl
    hyprpicker # color picker
    hyprcursor
    # wf-recorder # screen recording - broken?
    grim # taking screenshots
    slurp # selecting a region to screenshot

    font-awesome # icon font
    jetbrains-mono # mono font

    nemo-with-extensions # file manager gui
    junction # browser chooser

    # quickemu # virtual machines
  ];
}
