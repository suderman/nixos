{ config, pkgs, inputs, ... }: {

  imports = [ 
    inputs.hardware.nixosModules.lenovo-thinkpad-t480s
    ./hardware-configuration.nix
    ./storage.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

}
