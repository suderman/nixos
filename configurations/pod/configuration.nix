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
    # VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
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

  # services.xserver = {
  #   enable = true;
  #   deviceSection = ''
  #     Option "DRI" "3"
  #     Option "TearFree" "on"
  #   '';
  # };



  programs.hyprland = {
    enable = true;
  };

  # -------------------------
  programs.sway = {
    enable = true; 
    wrapperFeatures.gtk = true;
  };

  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
    grim # screenshot functionality
    slurp # screenshot functionality
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    mako # notification system developed by swaywm maintainer
    vulkan-tools
  ];

  services.xserver = {
    enable = true;
    # videoDrivers = [ "amdgpu" ];
    # Option "DRI3" "1"
    deviceSection = ''
      Option "DRI" "3"
      Option "TearFree" "on"
    '';
    displayManager.lightdm.enable = true;

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu #application launcher most people use
        i3status # gives you the default i3 status bar
        i3lock #default i3 screen locker
        i3blocks #if you are planning on using i3blocks over i3status
      ];
    };

  };
  # -------------------------

  # hardware.amdgpu = {
  #   loadInInitrd = true;
  #   amdvlk = false;
  #   opencl = true;
  # };
  #
  # hardware.opengl.extraPackages = with pkgs; [
  #   rocmPackages.clr.icd
  # ];

  file."/opt/rocm/hip" = { 
    type = "link"; 
    source = "${pkgs.rocmPackages.clr}";
  };

  # systemd.tmpfiles.rules = [
  #   "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  # ];

  # environment.systemPackages = with pkgs; [ 
  #   vulkan-tools
  # ];


}
