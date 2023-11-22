{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
    ./storage.nix
  ];

  # Use freshest kernel
  # boot.kernelPackages = pkgs.linuxPackages_latest;

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

  # Load nvidia driver for Xorg and Wayland
  # services.xserver.videoDrivers = [ "nvidia" ];
  # services.xserver.videoDrivers = [ "nvidia" "modesetting" "fbdev" ];
  # services.xserver.videoDrivers = [ "nvidia" "nvidiaLegacy470" "nvidiaLegacy390" ];

  # hardware.nvidia = {
  #
  #   # accessible via `nvidia-settings`.
  #   nvidiaSettings = true;
  #
  #   # Modesetting is required.
  #   modesetting.enable = true;
  #
  #   # GTX 780
  #   package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
  #   # package = config.boot.kernelPackages.nvidiaPackages.legacy_390;
  #   open = false;
  #
  # };

  services.xserver.desktopManager.xterm.enable = false;
  services.xserver.displayManager.defaultSession = "none+i3";
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      dmenu #application launcher most people use
      i3status # gives you the default i3 status bar
      i3lock #default i3 screen locker
      i3blocks #if you are planning on using i3blocks over i3status
    ];
  };

  # services.xserver.desktopManager.xterm.enable = false;
  # services.xserver.desktopManager.xfce.enable = true;
  # services.xserver.displayManager.defaultSession = "xfce";

  # services.xserver.desktopManager.retroarch = {
  #   enable = true;
  #   package = pkgs.retroarchFull;
  # };

}
