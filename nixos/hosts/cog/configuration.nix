{ inputs, config, lib, pkgs, ... }: {

  imports = [ 
    ../../. 
    ./hardware-configuration.nix 
    inputs.hardware.nixosModules.framework 
    inputs.agenix.nixosModule
  ];

  desktops.gnome.enable = true;

  services.tailscale.enable = true;
  services.openssh.enable = true;
  programs.mosh.enable = true;

  services.keyd.enable = true;
  
  services.traefik.enable = true;
  services.whoogle.enable = true;
  services.whoami.enable = true;

  programs.neovim.enable = true;

  # Flatpak
  services.flatpak.enable = true;
  xdg.portal.enable = true;
  # xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # services.sabnzbd.enable = true;
  # services.sabnzbd.user = "me";
  # services.sabnzbd.group = "users";

  # https://search.nixos.org/options?show=services.tandoor-recipes.enable&query=services.tandoor-recipes
  services.tandoor-recipes.enable = true;
  services.tandoor-recipes.port = 8081;

  # https://search.nixos.org/options?show=services.gitea.enable&query=services.gitea
  services.gitea.enable = true;
  services.gitea.database.type = "mysql";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  services.fprintd.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable sound.
  sound.enable = true;
  services.pipewire.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Steam
  programs.steam.enable = false;

  # Packages
  # environment.systemPackages = with pkgs; [];

  # Other
  # programs.nix-ld.enable = true;

}
