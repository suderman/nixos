{ inputs, config, pkgs, lib, ... }: {

  imports = [ ../.
    ./hardware-configuration.nix 
    inputs.hardware.nixosModules.framework
  ] ++ [
    ../keyd.nix
    ../wayland.nix
    ../gnome.nix
    ../vim.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  services.fprintd.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable sound.
  sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Packages
  environment.systemPackages = with pkgs; [];

  # Docker
  virtualisation.docker.enable = true;

  # Other
  # programs.nix-ld.enable = true;

}
