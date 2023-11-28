{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
    ./storage.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Memory management
  modules.earlyoom.enable = true;

  # Keyboard control
  modules.keyd.enable = true;
  modules.ydotool.enable = true;

  # Apps
  programs.mosh.enable = true;
  modules.neovim.enable = true;

  # Web services
  modules.tailscale.enable = true;
  modules.ddns.enable = true;
  modules.whoami.enable = true;
  modules.cockpit.enable = true;
  modules.withings-sync.enable = true;

  modules.unifi.enable = true;
  modules.home-assistant = {
    enable = true; ip = "192.168.1.4";
    zigbee = "/dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1.0_28b77f55258dec11915068e883c5466d-if00-port0";
    zwave = "/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_3e535b346625ed11904d6ac2f9a97352-if00-port0";
    isy = "192.168.2.3";
  };

  # Test services
  # modules.plex.enable = true;
  # modules.tautulli.enable = true;
  # modules.jellyfin.enable = true;
  # modules.tiddlywiki.enable = true;
  # modules.tandoor-recipes.enable = true;

}
