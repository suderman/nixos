{ config, lib, pkgs, this, profiles, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    profiles.services
    profiles.terminal
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Custom DNS
  services.blocky.enable = true;
  services.prometheus.enable = true;
  services.grafana.enable = true;

  # Hub for monitoring other machines
  services.beszel.enable = true;

  # Serve CA cert on http://10.1.0.4:1234
  services.traefik.enable = true;
  services.traefik.caPort = 1234;

  # LAN controller
  services.unifi = with this.networks; {
    enable = true;
    gateway = home.logos;
  };

  # Home automation
  services.home-assistant = with this.networks; {
    enable = true; 
    name = "hass";
    ip = home.hub;
    zigbee = "/dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1.0_28b77f55258dec11915068e883c5466d-if00-port0";
    zwave = "/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_3e535b346625ed11904d6ac2f9a97352-if00-port0";
    isy = home.isy;
  };

  # Reverse proxy for termux syncthing webgui running on my phone
  services.traefik.proxy."syncthing-jon.phone" = "http://phone.tail:8384";
  services.traefik.extraInternalHostNames = [ "syncthing-jon.phone" ];

}
