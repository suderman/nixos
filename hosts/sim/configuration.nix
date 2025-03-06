{ config, flake, modulesPath, pkgs, ... }: let
  inherit (builtins) mapAttrs;
in {

  imports = [
    flake.nixosModules.agenix
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  age = {
    rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1f7U6J47oadgOmHl9f7KEma7ChzTWRiQW4RU8lSKTl";
    secrets.fresh.rekeyFile = ./fresh.txt.age; 
  };

  boot.kernelParams = [ "console=ttyS0" "console=tty1" "boot.shell_on_fail" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.checkJournalingFS = false;

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.system-features = [ "kvm" ];

  environment.systemPackages = [
    pkgs.vim
  ];

  environment.etc = {
    "fresh.txt" = {
      source = config.age.secrets.fresh.path;
      mode = "0750";
      user = "jon";
      group = "users";
    };
  };

  # users.users.root = {
  #   initialPassword = "root";
  # };

  # Disallow modifying users outside of this config
  users.mutableUsers = false;

  users.users.jon = {
    createHome = true;
    isNormalUser = true;
    shell = pkgs.bash;
    uid = 1000;
    initialPassword = "jon";
    group = "users";
    extraGroups = [ "wheel" "input" ];
    linger = true;
  };

  users.groups.users = {};

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  virtualisation = {
    diskSize = 4096;   # Disk size in MB
    memorySize = 2048; # RAM in MB
    # qemu.networkingOptions = [ "-nic bridge,br=bridge0,model=virtio-net-pci,mac=52:54:00:12:34:56" ];
  };

  # networking.interfaces.enp0s1.macAddress = "52:54:00:12:34:56";

  networking.hostName = "sim";
  networking.firewall.allowPing = true;

  services.openssh.enable = true;

  system.stateVersion = "24.11";

}
