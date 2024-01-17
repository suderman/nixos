{ config, lib, pkgs, this, inputs, ... }: {

  # Import all *.nix files in this directory
  imports = this.lib.ls ./. ++ [
    inputs.hardware.nixosModules.framework-11th-gen-intel
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Good graphics
  hardware.opengl.extraPackages = with pkgs; [
    mesa.drivers
    vaapiVdpau
  ];

  # Sound & Bluetooth
  sound.enable = true;
  services.pipewire.enable = true;
  security.rtkit.enable = true;
  hardware.bluetooth.enable = true;

  # framework_tool
  environment.systemPackages = with pkgs; [
    framework-tool
  ];

  # Network
  modules.tailscale.enable = true;
  modules.ddns.enable = true;
  networking.networkmanager.enable = true;
  networking.extraHosts = ''
    127.0.0.1 example.com
  '';

  # sudo fwupdmgr update
  services.fwupd.enable = true;

  # Lower fan noise 
  services.thermald.enable = true;

  # Power management
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;
  services.tlp.settings = {
    SATA_LINKPWR_ON_BAT = "max_performance";
    # CPU_BOOST_ON_BAT = 0;
    # CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";
    # START_CHARGE_THRESH_BAT0 = 90;
    # STOP_CHARGE_THRESH_BAT0 = 97;
    # RUNTIME_PM_ON_BAT = "auto";
  };
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
    lidSwitchDocked = "ignore";
  };

  # Memory management
  modules.earlyoom.enable = true;


  # Keyboard control
  modules.keyd = {
    enable = true;
    quirks = true;
    settings = ./keyd.conf;
  };
  modules.ydotool.enable = true;

  modules.garmin.enable = true;
  modules.sunshine.enable = true;
  virtualisation.waydroid.enable = true;

  # Support iOS devices
  modules.libimobiledevice.enable = true;

  # Web services
  modules.whoami.enable = true;
  modules.tandoor-recipes.enable = false;
  modules.home-assistant.enable = false;
  modules.rsshub.enable = false;
  modules.backblaze.enable = false;
  modules.wallabag.enable = false;
  modules.cockpit.enable = false;
  modules.gitea.enable = false;
  modules.nextcloud.enable = false;
  modules.ocis = { enable = false; dataDir = "/tmp/ocis"; };
  modules.immich.enable = false;
  modules.photoprism = { enable = false; photosDir = "/photos"; };
  modules.silverbullet.enable = false;

  # Apps & Games
  modules.neovim.enable = true;
  modules.steam.enable = false;
  programs.mosh.enable = true;
  programs.kdeconnect.enable = true;
  programs.evolution.enable = true;
  modules.dolphin.enable = true;
  services.xserver.desktopManager.retroarch = {
    enable = false;
    package = pkgs.retroarchFull;
  };

  modules.flatpak = {
    enable = true;
    packages = [
      "app.bluebubbles.BlueBubbles"
      "io.github.dvlv.boxbuddyrs"
      "io.gitlab.zehkira.Monophony"
    ];
    betaPackages = [
      "org.gimp.GIMP" # https://www.gimp.org/downloads/devel
    ];
  };

  # Experiments
  systemd.user.services.foobar = {
    description = "Foobar NixOS";
    after = [ "graphical-session.target" ];
    requires = [ "graphical-session.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    environment = {
      FOO = "bar";
    };
    path = with pkgs; [ coreutils ];
    script = ''
      touch /tmp/foobar.txt
      date >> /tmp/foobar.txt
    '';
  };

  file."/etc/foo" = { type = "dir"; };
  file."/etc/foo/bar" = { text = "Hello world!"; mode = 665; user = 913; };
  file."/etc/foo/symlink" = { type = "link"; source = /etc/foo/bar; };
  file."/etc/foo/resolv" = { type = "file"; mode = 775; user = "me"; group = "users"; source = /etc/resolv.conf; };
  file."/etc/foo/srv" = { type = "dir"; source = /srv; };


  # # services.wordpress.webserver = "nginx";
  # services.wordpress.sites."wpcog" = {
  #   database.name = "wpcog";
  #   # virtualHost.documentRoot = "/var/lib/wordpress/wpcog/root";
  #   # virtualHost.serverAliases = [
  #   #   "wp.cog.suderman.org"
  #   #   "wp.cog.suderman.org:8080"
  #   #   "example.org"
  #   # ];
  #   # virtualHost.listen = [{
  #   #   ip = "*";
  #   #   port = 8080;
  #   # }];
  # };
  # services.httpd.virtualHosts."wpcog" = {
  #   documentRoot = lib.mkOverride 40 "/var/lib/wordpress/wpcog/root";
  #   serverAliases = [
  #     "wp.cog.suderman.org"
  #     "wp.cog.suderman.org:8080"
  #     "example.org"
  #   ];
  #   listen = [{
  #     ip = "*";
  #     port = 8080;
  #   }];
  # };


}
