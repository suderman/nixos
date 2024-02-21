{ config, pkgs, this, ... }: {

  # Import all *.nix files in this directory
  imports = this.lib.ls ./.;

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
  # modules.ddns.enable = true;
  modules.whoami.enable = true;
  modules.cockpit.enable = true;
  modules.withings-sync.enable = true;

  # Custom DNS
  modules.blocky.enable = true;

  # Serve CA cert on http://10.1.0.4:1234
  modules.traefik = {
    enable = true;
    caPort = 1234;
  };

  # LAN controller
  modules.unifi = with this.networks; {
    enable = true;
    gateway = home.logos;
  };

  # Home automation
  modules.home-assistant = with this.networks; {
    enable = true; 
    name = "hass";
    ip = home.hub;
    zigbee = "/dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1.0_28b77f55258dec11915068e883c5466d-if00-port0";
    zwave = "/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_3e535b346625ed11904d6ac2f9a97352-if00-port0";
    isy = home.isy;
  };

  # Test services
  # modules.plex.enable = true;
  # modules.tautulli.enable = true;
  # modules.jellyfin.enable = true;
  # modules.tiddlywiki.enable = true;
  # modules.tandoor-recipes.enable = true;

}
