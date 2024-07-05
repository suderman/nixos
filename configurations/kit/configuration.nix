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
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages_6_8;

  # Sound & Bluetooth
  sound.enable = true;
  hardware.bluetooth.enable = true;
  services.pipewire.enable = true;
  security.rtkit.enable = true;

  # Memory management
  services.earlyoom.enable = true;

  # Keyboard control
  services.keyd.enable = true;

  # Network
  networking.networkmanager.enable = true;
  services.tailscale = {
    enable = true;
    deleteRoute = "10.1.0.0/16";
  };

  services.garmin.enable = true;
  programs.hyprland.enable = true;
  services.whoami.enable = true;

  # Apps
  programs.dolphin.enable = true;
  programs.steam.enable = true;
  programs.neovim.enable = true;
  programs.mosh.enable = true;
  programs.kdeconnect.enable = true;

  modules.ollama.enable = true;
  services.ollama.acceleration = "cuda";

  services.flatpak = {
    enable = true;
    apps = [
      "app.bluebubbles.BlueBubbles"
      "io.github.dvlv.boxbuddyrs"
      "io.gitlab.zehkira.Monophony"
      "org.emptyflow.ArdorQuery"
      "com.github.treagod.spectator"
    ];
    beta = [
      "org.gimp.GIMP" # https://www.gimp.org/downloads/devel
    ];
  };

}
