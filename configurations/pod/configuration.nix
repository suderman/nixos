{ config, pkgs, this, inputs, ... }: {

  # Import all *.nix files in this directory
  imports = this.lib.ls ./. ++ [
    inputs.hardware.nixosModules.common-gpu-amd
  ];

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;

  # Memory management
  modules.earlyoom.enable = true;

  # Keyboard control
  services.keyd.enable = true;

  # Apps
  programs.mosh.enable = true;
  modules.neovim.enable = true;

  # Web services
  modules.tailscale = {
    enable = true;
    deleteRoute = "10.1.0.0/16";
  };
  # modules.ddns.enable = true;
  modules.whoami.enable = true;

  # modules.sunshine.enable = true;
  modules.dolphin.enable = true;
  modules.steam.enable = true;

  # https://wiki.nixos.org/wiki/AMD_GPU
  environment.variables = {
    ROC_ENABLE_PRE_VEGA = "1";
  };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      libvdpau-va-gl
      vaapiVdpau
      # amdvlk
    ];
    extraPackages32 = with pkgs; [
      libvdpau-va-gl
      vaapiVdpau
      # driversi686Linux.amdvlk
    ];
  };

  file."/opt/rocm/hip" = { 
    type = "link"; 
    source = "${pkgs.rocmPackages.clr}";
  };

}
