{ config, pkgs, lib, profiles, ... }: {

  imports = with profiles; [
    gaming # steam and emulation
  ];

  # Desktop environment
  services.xserver.desktopManager.gnome.enable = false;
  programs.hyprland = {
    enable = true;
    autologin = "jon";
  };

  services.flatpak.enable = true;

  # AirDrop alternative
  programs.localsend.enable = true; 

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;
  };

}
