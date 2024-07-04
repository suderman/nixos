{ config, lib, pkgs, presets, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    presets.lenovo-thinkpad-t480s
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Memory management
  services.earlyoom.enable = true;

  # Keyboard control
  services.keyd.enable = true;

  # Apps
  programs.mosh.enable = true;
  programs.neovim.enable = true;

  # Web services
  services.tailscale.enable = true;
  services.whoami.enable = true;

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "ness";

}
