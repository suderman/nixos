{ config, lib, pkgs, inputs, presets, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    presets.common-gpu-amd
  ];

  # Use freshest kernel
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackages_6_6; # build failure on 6.12

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;

  # Memory management
  services.earlyoom.enable = true;

  # Keyboard control
  services.keyd.enable = true;

  # Apps
  programs.mosh.enable = true;
  programs.neovim.enable = true;
  programs.dolphin.enable = true;
  programs.steam.enable = true;
  services.whoami.enable = true;

  # AirDrop alternative
  programs.localsend.enable = true; 
  networking.firewall = let port = 53317; in {
    allowedTCPPorts = [ port ];
    allowedUDPPorts = [ port ];
  };

  # Web services
  services.tailscale = {
    enable = true;
    deleteRoute = "10.1.0.0/16";
  };

  # Desktop environment
  services.xserver.desktopManager.gnome.enable = false;
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    autologin = "jon";
  };

  # https://wiki.nixos.org/wiki/AMD_GPU
  environment.variables = {
    ROC_ENABLE_PRE_VEGA = "1";
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
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

  stylix = {
    enable = true;
    cursor = {
      name = "Banana";
      package = pkgs.banana-cursor;
      size = 50;
    };
  };

}
