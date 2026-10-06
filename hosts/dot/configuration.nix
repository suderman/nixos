{
  config,
  flake,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.default
  ];

  system.stateVersion = lib.mkForce "26.05";
  networking.domain = "tail";
  time.timeZone = "America/Toronto";
  boot.kernelPackages = pkgs.linuxPackages;
  boot.loader.grub.configurationLimit = 5;

  # Linode DHCP uses eth0. Keep one network manager and no home subnet routes.
  networking.networkmanager.enable = lib.mkForce false;
  networking.enableIPv6 = true;
  networking.tempAddresses = "disabled";
  networking.nameservers = ["1.1.1.1" "9.9.9.9"];
  services.tailscale.extraSetFlags = lib.mkForce ["--accept-routes=false" "--accept-dns=false"];

  # Keep shared monitoring on Tailscale, not the public interface.
  networking.firewall = {
    allowedTCPPorts = lib.mkForce [22];
    allowedUDPPorts = lib.mkForce [41641];
    interfaces.tailscale0.allowedTCPPorts =
      lib.optional config.services.beszel.enableAgent config.services.beszel.agentPort;
  };

  services.openssh.settings = {
    PermitRootLogin = lib.mkForce "prohibit-password";
    KbdInteractiveAuthentication = false;
  };
  systemd.services."serial-getty@ttyS0".enable = true;
  systemd.enableEmergencyMode = true;
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=128M
    MaxRetentionSec=7day
  '';

  # No public applications during commissioning. Use normal fleet snapshots;
  # choose and verify off-host destinations before declaring backups ready.
  services.blocky.enable = false;
  services.traefik.enable = false;
  services.whoami.enable = false;
  services.keyd.enable = false;
  programs.mosh.openFirewall = false;

  # Build on the operator while the small cloud host is being commissioned.
  nix.settings = {
    download-buffer-size = lib.mkForce 16777216;
    http-connections = lib.mkForce 4;
    max-substitution-jobs = lib.mkForce 2;
    max-jobs = 1;
    cores = 1;
  };
  system.autoUpgrade.enable = false;
  nix.gc.automatic = lib.mkForce false;
}
