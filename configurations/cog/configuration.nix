{ config, lib, pkgs, inputs, gui, ... }: {

  imports = [ 
    inputs.hardware.nixosModules.framework 
    ./framework.nix
    ./hardware-configuration.nix 
    ./storage.nix
  ];

  # Base configuration
  modules.base.enable = true;
  modules.secrets.enable = true;

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  modules.tailscale.enable = true;
  modules.ddns.enable = true;
  networking.extraHosts = ''
    127.0.0.1 example.com
  '';

  # Broken? Prevents boot.
  # modules.sunshine.enable = false;

  # Memory management
  modules.earlyoom.enable = true;

  # Keyboard control
  modules.keyd.enable = true;
  modules.ydotool.enable = true;

  # Support iOS devices
  modules.libimobiledevice.enable = true;

  # # Database services
  # modules.mysql.enable = true;
  # modules.postgresql.enable = true;
  
  # Web services
  modules.whoami.enable = true;
  modules.tandoor-recipes.enable = false;
  modules.home-assistant.enable = false;
  modules.rsshub.enable = false;
  modules.backblaze.enable = false;
  modules.wallabag.enable = true;

  modules.cockpit.enable = true;

  modules.nextcloud.enable = false;
  modules.ocis.enable = false;

  modules.immich = {
    enable = false;
    photosDir = "/photos/immich";
  };

  modules.photoprism = {
    enable = false;
    photosDir = "/photos";
  };

  # Desktop Environments
  modules.gnome.enable = (if gui == "gnome" then true else false);
  modules.hyprland.enable = (if gui == "hyprland" then true else false);

  modules.dolphin.enable = true;

  # Apps
  modules.flatpak.enable = true;
  modules.neovim.enable = true;
  modules.steam.enable = false;

  programs.mosh.enable = true;
  programs.kdeconnect.enable = true;

  programs.evolution.enable = true;

  # sudo fwupdmgr update
  services.fwupd.enable = true;

  # # Power management
  # services.tlp.enable = false;
  # services.tlp.settings = {
  #   CPU_BOOST_ON_BAT = 0;
  #   CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";
  #   START_CHARGE_THRESH_BAT0 = 90;
  #   STOP_CHARGE_THRESH_BAT0 = 97;
  #   RUNTIME_PM_ON_BAT = "auto";
  # };

  # # Suspend-then-hibernate after two hours
  # services.logind = {
  #   lidSwitch = "suspend-then-hibernate";
  #   lidSwitchExternalPower = "suspend";
  #   extraConfig = ''
  #     HandlePowerKey=suspend-then-hibernate
  #     IdleAction=suspend-then-hibernate
  #     IdleActionSec=2m
  #   '';
  # };
  # systemd.sleep.extraConfig = "HibernateDelaySec=2h";
  services.logind = {
    lidSwitch = "lock";
    lidSwitchExternalPower = "lock";
    lidSwitchDocked = "ignore";
    # extraConfig = ''
    #   IdleActionSec=30m
    #   IdleAction=hibernate
    #   HandlePowerKey=hibernate
    # '';
  };
  # services.udev.extraRules = lib.mkAfter ''
  #   ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{power/wakeup}="enabled"
  # '';


}
