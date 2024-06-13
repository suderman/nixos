{ config, pkgs, lib, presets, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    presets.rtx-4070-ti-super
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;

  # Use freshest kernel
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackages_6_8;

  # Sound & Bluetooth
  sound.enable = true;
  hardware.bluetooth.enable = true;
  services.pipewire.enable = true;
  security.rtkit.enable = true;

  # services.xserver = {
  #   enable = true;
  #   desktopManager.xterm.enable = true;
  #   desktopManager.xfce.enable = true;
  #   displayManager.defaultSession = "xfce";
  # };
  # xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  # # xdg.portal.enable = lib.mkForce false;

  # Memory management
  modules.earlyoom.enable = true;

  # Keyboard control
  services.keyd.enable = true;

  # Network
  networking.networkmanager.enable = true;
  modules.tailscale = {
    enable = true;
    deleteRoute = "10.1.0.0/16";
  };

  programs.hyprland.enable = true;

  modules.garmin.enable = true;

  # Support iOS devices
  # modules.libimobiledevice.enable = true;

  # modules.ddns.enable = true;
  modules.whoami.enable = true;

  # Apps
  # modules.sunshine.enable = true;
  modules.dolphin.enable = true;
  modules.steam.enable = true;
  modules.neovim.enable = true;
  programs.mosh.enable = true;
  programs.kdeconnect.enable = true;
  # programs.evolution.enable = true;

  modules.ollama.enable = true;
  services.ollama.acceleration = "cuda";


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

  # Stable Diffusion
  modules.traefik.routers.sd = "http://127.0.0.1:7860";
  modules.traefik.routers."sd.suderman.org" = {
    url = "http://127.0.0.1:7860";
    public = false;
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
  file."/etc/foo/resolv" = { type = "file"; mode = 775; user = "jon"; group = "users"; source = /etc/resolv.conf; };
  file."/etc/foo/srv" = { type = "dir"; source = /srv; };

}
