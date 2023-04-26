{ config, lib, pkgs, inputs, ... }: {

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
  networking.extraHosts = "";

  # Broken? Prevents boot.
  # modules.sunshine.enable = false;

  # Memory management
  modules.earlyoom.enable = true;

  # Keyboard control
  modules.keyd.enable = true;
  modules.ydotool.enable = true;

  # Database services
  modules.mysql.enable = true;
  modules.postgresql.enable = true;
  
  # Web services
  modules.whoami.enable = true;
  modules.tandoor-recipes.enable = false;
  modules.home-assistant.enable = false;
  modules.immich.enable = false;
  modules.rsshub.enable = false;

  modules.backblaze = {
    enable = true;
    backupDir = "/home";
  };

  # Desktop Environments
  modules.gnome.enable = true;

  # Apps
  modules.flatpak.enable = true;
  modules.neovim.enable = true;
  modules.steam.enable = false;

  programs.mosh.enable = true;
  programs.kdeconnect.enable = true;

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

  services.xserver.displayManager.gdm.debug = true;

  # sudo fwupdmgr update
  services.fwupd.enable = true;

  # services.fprintd.enable = true;
  # services.fprintd.tod.enable = true;
  # services.fprintd.tod.driver = pkgs.libfprint-2-tod1-vfs0090;  # (If the vfs0090 Driver does not work, use the following driver)
  # # services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix; # (On my device it only worked with this driver)
  
  environment.systemPackages = with pkgs; [ 
    monica
    unstable.nodePackages_latest.immich
    unstable.figma-linux
  ];
  
  
  # systemd.mounts = [{
  #   what = "/dev/sda1";
  #   where = "/mnt/usb";
  #   options = "defaults,noauto,x-systemd.automount";
  #   wantedBy = ["multi-user.target"];
  # }];
}
