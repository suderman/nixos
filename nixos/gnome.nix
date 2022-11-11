{ config, lib, pkgs, ... }: {

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

  environment.systemPackages = with pkgs; [
    gnome.gnome-software
    gnome.gnome-tweaks
  ];

  # Fix broken stuff
  # services.avahi.enable = false;
  # networking.networkmanager.enable = false;

}
