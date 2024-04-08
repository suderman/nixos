{ config, pkgs, inputs, this, ... }: {

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

  # Memory management
  modules.earlyoom.enable = true;

  # Keyboard control
  modules.keyd.enable = true;
  modules.ydotool.enable = true;

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
  modules.cockpit.enable = true;

  # modules.sunshine.enable = true;
  modules.dolphin.enable = true;
  modules.steam.enable = true;

  # Enable OpenGL
  # hardware.opengl = {
  #   enable = true;
  #   driSupport = true;
  #   driSupport32Bit = true;
  #   extraPackages = with pkgs; [
  #     amdvlk
  #     # vulkan-loader
  #     # vulkan-validation-layers
  #     # vulkan-extension-layer
  #   ];
  # };
  #
  # environment.variables = {
  #   AMD_VULKAN_ICD = "RADV";
  # };
  #
  # boot.initrd.kernelModules = ["amdgpu"];
  # services.xserver.videoDrivers = ["amdgpu"];

  # https://wiki.nixos.org/wiki/AMD_GPU
  environment.variables = {
    ROC_ENABLE_PRE_VEGA = "1";
  };

  # hardware.amdgpu = {
  #   loadInInitrd = true;
  #   amdvlk = false;
  #   opencl = true;
  # };
  #
  # hardware.opengl.extraPackages = with pkgs; [
  #   rocmPackages.clr.icd
  # ];

  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  environment.systemPackages = with pkgs; [ 
    vulkan-tools
  ];

}
