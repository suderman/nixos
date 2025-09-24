{
  pkgs,
  flake,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.hardware.vm
    flake.nixosModules.default
    flake.nixosModules.desktops.hyprland
    # flake.nixosModules.desktops.homelab
  ];

  config = {
    networking.domain = "tail";

    # Override encrypted/hashed password with this
    # users.users.jon.password = "x";

    # Grant ssh host key access to root login
    users.users.root.openssh.authorizedKeys.keyFiles = [
      ./ssh_host_ed25519_key.pub
    ];

    environment.systemPackages = [
      pkgs.mesa
      pkgs.vulkan-loader
      pkgs.vulkan-tools # for `vulkaninfo`
      pkgs.libvdpau-va-gl
      pkgs.glxinfo # for checking OpenGL
    ];

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

    # Hub for monitoring other machines
    services.beszel.enable = true;
    services.postgresql.enable = true;
    services.immich = {
      enable = true;
      # photosDir = "/data/photos/immich";
      # externalDir = "/data/photos/collections";
      # alias = "immich.suderman.org";
    };
  };
}
