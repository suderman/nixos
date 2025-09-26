# Nvidia GeForce RTX 4070 Ti Super
{
  config,
  pkgs,
  flake,
  ...
}: let
  # https://raw.githubusercontent.com/aaronp24/nvidia-versions/master/nvidia-versions.txt
  beta = true; # I want to use current LTS, so setting this to true
in {
  # https://github.com/NixOS/nixos-hardware/tree/master/common/gpu/nvidia
  imports = [flake.inputs.hardware.nixosModules.common-gpu-nvidia-nonprime];

  boot.initrd.kernelModules = ["nvidia"];
  boot.extraModulePackages = with config.boot.kernelPackages;
    if beta
    then [nvidia_x11_beta]
    else [nvidia_x11];

  # Current LTS kernel 6.12 seems to work better with nvidia's beta driver
  # If not using beta, stay on previous LTS kernel 6.6 for now
  boot.kernelPackages =
    if beta
    then pkgs.linuxPackages_6_12
    else pkgs.linuxPackages_6_6;

  # Fix extra screen
  boot.kernelParams = ["nvidia-drm.fbdev=1"];

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
    # if beta then nvidiaPackages.beta else nvidiaPackages.latest;
      if beta
      then nvidiaPackages.beta
      else nvidiaPackages.production; # https://github.com/NixOS/nixpkgs/pull/365711
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Enable dynamic CDI configuration for NVidia devices by running nvidia-container-toolkit on boot
  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.docker.daemon.settings.features.cdi = true;

  environment.systemPackages = with pkgs; [
    nvitop
    # docker-nvidia-smi # test nvidia in docker container
  ];

  # nvidia-smi included in monitoring
  services.beszel.extraPackages = [config.hardware.nvidia.package.bin];
}
