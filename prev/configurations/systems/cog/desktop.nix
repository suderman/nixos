{ config, lib, pkgs, ... }: {

  # Desktop environment
  programs.hyprland.enable = true; # also enables home-manager configuration
  # services.xserver.desktopManager.gnome.enable = false;

}
