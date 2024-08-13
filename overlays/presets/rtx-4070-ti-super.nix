# Nvidia GeForce RTX 4070 Ti Super
{ config, pkgs, lib, presets, ... }: {

  # https://github.com/NixOS/nixos-hardware/tree/master/common/gpu/nvidia
  imports = [ presets.common-gpu-nvidia-nonprime ];

  boot.initrd.kernelModules = [ "nvidia" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
  # boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11_beta ];

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
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/nvidia-x11/default.nix
    # package = config.boot.kernelPackages.nvidiaPackages.production;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    # package = config.boot.kernelPackages.nvidiaPackages.beta;

    # https://raw.githubusercontent.com/aaronp24/nvidia-versions/master/nvidia-versions.txt
    # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    #   version = "555.42.02";
    #   sha256_64bit = "sha256-k7cI3ZDlKp4mT46jMkLaIrc2YUx1lh1wj/J4SVSHWyk=";
    #   sha256_aarch64 = lib.fakeSha256;
    #   openSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
    #   settingsSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
    #   persistencedSha256 = lib.fakeSha256;
    # };

  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Enable dynamic CDI configuration for NVidia devices by running nvidia-container-toolkit on boot
  hardware.nvidia-container-toolkit.enable = true;

  virtualisation = {
    docker.enableNvidia = true; # This is supposedly depecrated, replaced by the hardware line above?
    docker.package = pkgs.docker_25; # CDI is feature-gated and only available from Docker 25 and onwards
    docker.daemon.settings.features.cdi = true;
  };

  # libnvidia-container does not support cgroups v2 (prior to 1.8.0)
  # https://github.com/NVIDIA/nvidia-docker/issues/1447
  # systemd.enableUnifiedCgroupHierarchy = false;

  environment.systemPackages = with pkgs; [ 
    nvitop
    docker-nvidia-smi # test nvidia in docker container
  ];

}
