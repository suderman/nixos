# Nvidia GeForce RTX 4070 Ti Super
{ config, pkgs, lib, presets, ... }: let

  # https://raw.githubusercontent.com/aaronp24/nvidia-versions/master/nvidia-versions.txt
  beta = false;

in {

  # https://github.com/NixOS/nixos-hardware/tree/master/common/gpu/nvidia
  imports = [ presets.common-gpu-nvidia-nonprime ];

  boot.initrd.kernelModules = [ "nvidia" ];
  boot.extraModulePackages = with config.boot.kernelPackages; 
    if beta then [ nvidia_x11_beta ] else [ nvidia_x11 ];

  # 560.35.03 "latest" broken on LTS kernel 6.12, use previous LTS kernel 6.6
  # https://github.com/NixOS/nixpkgs/commit/8653ea453d81a7320c63f930911bcd9f7e063c65
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_6; 

  # Fix extra screen
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

  # Good graphics
  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    powerManagement.finegrained = false;

    # Disable open source kernel module
    open = false;

    # nvidia-settings
    nvidiaSettings = true;

    # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/nvidia-x11/default.nix
    package = with config.boot.kernelPackages; 
      if beta then nvidiaPackages.beta else nvidiaPackages.latest;

  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Enable dynamic CDI configuration for NVidia devices by running nvidia-container-toolkit on boot
  hardware.nvidia-container-toolkit.enable = true;

  virtualisation = {
    docker.package = pkgs.docker_25; # CDI is feature-gated and only available from Docker 25 and onwards
    docker.daemon.settings.features.cdi = true;
  };

  environment.systemPackages = with pkgs; [ 
    nvitop
    docker-nvidia-smi # test nvidia in docker container
  ];

}
