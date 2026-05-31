# Nvidia GeForce RTX 4070 Ti Super
{
  config,
  pkgs,
  flake,
  ...
}: let
  # NixOS 26.05 follows NVIDIA's official branch names.
  # `production` is the long-lived stable branch; `beta` is now strictly beta.
  nvidiaBranch = "production";
in {
  # https://github.com/NixOS/nixos-hardware/tree/master/common/gpu/nvidia
  imports = [flake.inputs.hardware.nixosModules.common-gpu-nvidia-nonprime];

  boot.initrd.kernelModules = ["nvidia"];

  # Current upstream longterm kernel.
  boot.kernelPackages = pkgs.linuxPackages_6_18;

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

    # nvidia-settings
    nvidiaSettings = true;

    # Ada supports the open module, but keep proprietary until explicitly tested.
    # https://wiki.nixos.org/wiki/NVIDIA
    open = false;

    # Use the official stable production branch on NixOS 26.05.
    branch = nvidiaBranch;
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
    self.docker-nvidia-smi # test nvidia in docker container
  ];

  # nvidia-smi included in monitoring
  services.beszel.extraPackages = [config.hardware.nvidia.package.bin];

  # binary cache
  nix.settings = {
    substituters = ["https://cache.nixos-cuda.org?priority=50"];
    trusted-public-keys = ["cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="];
  };
}
