{ config, pkgs, inputs, this, ... }: {

  # Import all *.nix files in this directory
  imports = this.lib.ls ./. ++ [
    inputs.hardware.nixosModules.lenovo-thinkpad-t480s
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
  modules.neovim.enable = true;

  # Web services
  services.tailscale.enable = true;
  modules.ddns.enable = true;
  services.whoami.enable = true;

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "ness";

}
