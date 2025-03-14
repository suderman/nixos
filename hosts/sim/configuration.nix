{ config, flake, modulesPath, pkgs, lib, ... }: let
  inherit (builtins) mapAttrs;
  inherit (lib) mkOption types;
in {

  imports = [
    flake.nixosModules.agenix
    flake.nixosModules.homelab
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  config = {

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
    };

    networking.hostName = "sim";
    networking.hostPubkey = ./ssh_host_ed25519_key.pub;
    networking.hostPrvkey = ./ssh_host_ed25519_key.age;
    networking.firewall.allowPing = true;

    age.secrets.fresh.rekeyFile = ./fresh.txt.age; 
    # test.foo = config.age.secrets.foo.path;

    services.tailscale.enable = true;
    services.openssh.enable = true;

    system.stateVersion = "24.11";

  };
}
