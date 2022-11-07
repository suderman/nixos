{ outputs, pkgs, lib, config, ... }:

{
  services = {
    xserver = {
      desktopManager.gnome.enable = true;
      displayManager.gdm = {
        enable = true;
        autoSuspend = true;
      };
    };
    geoclue2.enable = true;
    gnome.games.enable = true;
  };

  environment.systemPackages = [
    pkgs.gnome.gnome-software
  ];

  # Fix broken stuff
  # services.avahi.enable = false;
  # networking.networkmanager.enable = false;
}
