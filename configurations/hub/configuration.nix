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
  services.flatpak.enable = true;
  programs.mosh.enable = true;
  programs.neovim.enable = true;

  services.plex.enable = true;
  services.tautulli.enable = true;
  services.jellyfin.enable = true;

}