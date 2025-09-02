{
  config,
  pkgs,
  lib,
  perSystem,
  flake,
  ...
}: let
  inherit (builtins) mapAttrs;
  inherit (lib) mkOption types;
  inherit (perSystem.self) mkApplication;
in {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.common
    flake.nixosModules.extra
    # flake.nixosModules.gnome
    flake.nixosModules.hyprland
    flake.nixosModules.vm
    # flake.nixosModules.homelab
  ];

  config = {
    networking.domain = "tail";
    networking.firewall.allowPing = true;

    # Override encrypted/hashed password with this
    # users.users.jon.password = "x";

    environment.systemPackages = [
      pkgs.yazi
      (mkApplication {
        name = "yo";
        text = "echo yooooo";
        desktopName = "Yo!";
        icon = flake + /prev/modules/zwift/user/zwift.svg;
        version = "2.0";
      })
      pkgs.fastfetch
      pkgs.cmatrix
      # pkgs.unstable.blocky

      pkgs.mesa
      pkgs.vulkan-loader
      pkgs.vulkan-tools # for `vulkaninfo`
      pkgs.libvdpau-va-gl
      pkgs.glxinfo # for checking OpenGL
    ];

    # services.tailscale.enable = true;
    # services.traefik.enable = true;
    # services.whoami.enable = true;
    # services.blocky.enable = true;
    # services.btrbk.enable = true;
    services.postgresql.enable = true;

    services.immich = {
      enable = true;
      # photosDir = "/data/photos/immich";
      # externalDir = "/data/photos/collections";
      # alias = "immich.suderman.org";
    };

    # # Keyboard control
    # services.keyd.enable = true;

    # App Store
    services.flatpak.enable = true;

    # # Prettify
    # stylix.enable = true;

    # Grant ssh host key access to root login
    users.users.root.openssh.authorizedKeys.keyFiles = [
      ./ssh_host_ed25519_key.pub
    ];

    programs.firefox.enable = true;

    # Hub for monitoring other machines
    services.beszel.enable = true;

    # Agent to monitor system
    # services.beszel.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGo/UVSuyrSmtE3RA0rxXpwApHEGMGOTd2c0EtGeCGAr";

    # For newer NixOS versions (23.11+), use:
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Enable QEMU with GPU passthrough support
    virtualisation.libvirtd.qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [pkgs.OVMFFull.fd];
      };
    };

    # services = {
    #   xserver = {
    #     desktopManager.gnome.enable = true;
    #     displayManager.gdm.enable = true;
    #     displayManager.gdm.autoSuspend = true;
    #   };
    # };

    # Enable virtualization
    virtualisation.libvirtd.enable = true;

    # Add your user to the libvirtd group
    users.users.jon.extraGroups = ["libvirtd"];

    # Snapshots
    services.btrbk.volumes = {
      "/mnt/main" = [];
      "/mnt/data" = [];
      "/mnt/pool" = [];
    };
  };
}
