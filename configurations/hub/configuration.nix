{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
  ];

  base.enable = true;
  state.enable = true;
  secrets.enable = true;

  # Configure the SSH daemon
  services.openssh.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Snapshots & backup
  services.btrbk.enable = true;

  # Memory management
  services.earlyoom.enable = true;

  # Keyboard control
  services.keyd.enable = true;
  services.ydotool.enable = true;

  # Web services
  services.tailscale.enable = true;
  services.ddns.enable = true;
  services.traefik.enable = true;
  services.whoami.enable = true;

  # Apps
  programs.mosh.enable = true;
  programs.neovim.enable = true;

  services.plex.enable = true;
  services.tautulli.enable = true;
  services.jellyfin.enable = true;
  services.tiddlywiki.enable = true;
  services.tandoor-recipes.enable = true;

  services.docker-unifi.enable = true;
  # services.docker-hass.enable = true;

  services.docker-hass = {
    enable = true;
    zigbee = "/dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1.0_28b77f55258dec11915068e883c5466d-if00-port0";
    zwave = "/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_3e535b346625ed11904d6ac2f9a97352-if00-port0";
  };

}
