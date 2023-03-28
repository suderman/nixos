{ config, lib, pkgs, inputs, ... }: {

  imports = [ 
    inputs.hardware.nixosModules.framework 
    ./framework.nix
    ./hardware-configuration.nix 
  ];

  # Btrfs mount options
  fileSystems."/".options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ];
  fileSystems."/nix".options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ];

  # Base configuration
  base.enable = true;
  state.enable = true;
  secrets.enable = true;

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  services.tailscale.enable = true;
  services.ddns.enable = true;
  services.openssh.enable = true;
  networking.extraHosts = "";

  # Snapshots & backup
  services.btrbk.enable = true;

  # Broken? Prevents boot.
  # services.sunshine.enable = false;

  # Memory management
  services.earlyoom.enable = true;

  # Keyboard control
  services.keyd.enable = true;
  services.ydotool.enable = true;

  # Database services
  services.mysql.enable = true;
  # services.postgresql.enable = false;
  
  # Web services
  services.traefik.enable = true;
  services.whoogle.enable = false;
  services.whoami.enable = true;
  services.sabnzbd.enable = false;
  services.tandoor-recipes.enable = true;
  # services.gitea.enable = true;
  # services.gitea.database.type = "mysql";

  # Desktop Environments
  desktops.gnome.enable = true;

  # Apps
  services.flatpak.enable = true;
  programs.mosh.enable = true;
  programs.neovim.enable = true;
  programs.steam.enable = false;

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

  services.docker-hass.enable = false;

  # services.fprintd.enable = true;
  # services.fprintd.tod.enable = true;
  # services.fprintd.tod.driver = pkgs.libfprint-2-tod1-vfs0090;  # (If the vfs0090 Driver does not work, use the following driver)
  # # services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix; # (On my device it only worked with this driver)
  
  environment.systemPackages = with pkgs; [ 
    monica
  ];
  
}
