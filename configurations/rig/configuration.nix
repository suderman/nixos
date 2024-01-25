{ config, pkgs, inputs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
    ./storage.nix
    inputs.hardware.nixosModules.common-gpu-amd
  ];

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

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

  modules.dolphin.enable = true;

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

}
