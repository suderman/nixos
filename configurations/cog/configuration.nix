{ config, lib, pkgs, presets, ... }: let 

  inherit (builtins) toString;

in {
  

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    presets.framework-11th-gen-intel
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Good graphics
  hardware.graphics.extraPackages = with pkgs; [
    mesa.drivers
    vaapiVdpau
  ];

  # Sound & Bluetooth
  sound.enable = true;
  services.pipewire.enable = true;
  security.rtkit.enable = true;
  hardware.bluetooth.enable = true;
  # hardware.pulseaudio.enable = true;

  # framework_tool
  environment.systemPackages = with pkgs; [
    framework-tool
  ];

  # Network
  services.tailscale.enable = true;
  networking.networkmanager.enable = true;
  networking.extraHosts = ''
    127.0.0.1 example.com
    127.0.0.1 local
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
  };
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
    lidSwitchDocked = "ignore";
  };

  # Memory management
  services.earlyoom.enable = true;

  # Keyboard control
  services.keyd = {
    enable = true;
    quirks = true;
    keyboard = config.services.keyd.internalKeyboards.framework;
  };

  services.garmin.enable = true;
  programs.hyprland.enable = true;

  # Web services
  services.traefik.enable = true;
  modules.whoami.enable = true;

  # Apps & Games
  modules.neovim.enable = true;
  modules.steam.enable = true;
  programs.mosh.enable = true;
  programs.kdeconnect.enable = true;
  # programs.evolution.enable = true;
  modules.dolphin.enable = true;
  # services.xserver.desktopManager.retroarch = {
  #   enable = false;
  #   package = pkgs.retroarchFull;
  # };

  modules.flatpak = {
    packages = [
      "app.bluebubbles.BlueBubbles"
      "io.github.dvlv.boxbuddyrs"
      "io.gitlab.zehkira.Monophony"
      "org.emptyflow.ArdorQuery"
      "com.github.treagod.spectator"
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

  services.ocis = {
    enable = true;
    url = "http://127.0.0.1:9200";
    environment = with config.services.ocis; {
      OCIS_INSECURE = "true";
      # OCIS_URL = "https://ocis.cog";
      # PROXY_HTTP_ADDR = "${address}:${toString port}";
      # PROXY_TLS = "false";
    };
  };

  file."${config.services.ocis.stateDir}" = { 
    type = "dir"; 
    mode = 775; 
    user = config.services.ocis.user; 
    group = config.services.ocis.group; 
  };

  file."/etc/foo" = { type = "dir"; };
  file."/etc/foo/bar" = { text = "Hello world!"; mode = 665; user = 913; };
  file."/etc/foo/symlink" = { type = "link"; source = /etc/foo/bar; };
  file."/etc/foo/resolv" = { type = "file"; mode = 775; user = "jon"; group = "users"; source = /etc/resolv.conf; };
  file."/etc/foo/srv" = { type = "dir"; source = /srv; };

  # modules.gitea.enable = true;
  # modules.radarr.enable = true;
  # modules.sonarr.enable = true;
  # modules.lidarr.enable = true;
  # modules.sabnzbd.enable = true;
  # modules.tandoor-recipes.enable = false;
  # modules.home-assistant.enable = true;
  # modules.rsshub.enable = true;
  # modules.backblaze.enable = false;
  # modules.wallabag.enable = false;
  # modules.jellyfin.enable = false;
  # modules.unifi = with this.network.dns; {
  #   enable = true;
  #   gateway = home.logos;
  # };
  # modules.freshrss.enable = true;
  # modules.whoogle = { enable = true; name = "g"; };
  # modules.nextcloud.enable = false;
  # modules.tiddlywiki.enable = true;
  # modules.ocis = { enable = true; dataDir = "/tmp/ocis"; };
  # modules.photoprism = { enable = false; photosDir = "/photos"; };
  # modules.silverbullet.enable = true;
  # modules.bluebubbles.enable = true;
  # services.traefik = { 
  #   routers.isy = "http://${this.networks.home.isy}:80";
  #   dynamicConfigOptions.http = {
  #     middlewares.isy.headers.customRequestHeaders.authorization = "Basic {{ env `ISY_BASIC_AUTH` }}";
  #   };
  #   routers."foo.bar" = "https://whoami.cog";
  # };


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
