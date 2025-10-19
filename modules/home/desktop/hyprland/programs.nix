# Programs and packages required by my Hyprland
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkForce;

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
        # (restart "swww")
      ];
  };
in {
  # Check modules directory for extra configuration
  programs = {
    bluetuith.enable = true; # bluetooth tui
    cava.enable = true; # audio visualizer
    rofi.enable = true; # launcher
    printscreen.enable = true; # screenshots
  };

  systemd.user.services.swww = {
    Install.WantedBy = mkForce [cfg.systemd.target];
    Unit.PartOf = mkForce [cfg.systemd.target];
    Unit.After = mkForce [cfg.systemd.target];
  };

  services = {
    swww.enable = true; # wallpaper
  };

  # Add these to my path
  home.packages = with pkgs; [
    bounce # defined above
    brightnessctl
    hyprcursor

    font-awesome # icon font
    jetbrains-mono # mono font

    nemo-with-extensions # file manager gui
    junction # browser chooser

    # quickemu # virtual machines
  ];
}
