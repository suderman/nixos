{ inputs, pkgs, lib, ... }: {

  imports = [ ../.
    ./hardware-configuration.nix 
    inputs.hardware.nixosModules.framework
  ] ++ [
    ../keyd.nix
    ../wayland.nix
    ../gnome.nix
    ../vim.nix
  ];

  networking.hostName = "cog"; 
  # networking.domain = "example.com";

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

  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [];

  virtualisation.docker.enable = true;
  programs.nix-ld.enable = true;

}
