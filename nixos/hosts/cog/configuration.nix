{ inputs, config, lib, pkgs, ... }: {

  imports = [ 
    ../. 
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
  # services.whoogle.enable = true;
  services.whoami.enable = true;

  programs.neovim.enable = true;

  # Flatpak
  services.flatpak.enable = true;

  services.sabnzbd.enable = true;

  # https://search.nixos.org/options?show=services.tandoor-recipes.enable&query=services.tandoor-recipes
  services.tandoor-recipes.enable = true;

  # https://search.nixos.org/options?show=services.gitea.enable&query=services.gitea
  services.gitea.enable = true;
  services.gitea.database.type = "mysql";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  services.fprintd.enable = true;

  # Steam
  programs.steam.enable = false;

  # Packages
  # environment.systemPackages = with pkgs; [];

  # Other
  # programs.nix-ld.enable = true;

}
