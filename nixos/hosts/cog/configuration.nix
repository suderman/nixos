{ inputs, config, lib, pkgs, ... }: {

  imports = [ 
    ../. 
    ./hardware-configuration.nix 
    inputs.hardware.nixosModules.framework 
  ];


  # noatime,compress=zstd,space_cache=v2,discard=async,subvol=@nix
  # fileSystems."/nix" = { 
  #   device = "/dev/disk/by-uuid/f73c53b7-ae6c-4240-89c3-511ad918edcc";
  #   fsType = "btrfs";
  #   options = [ "subvol=nix" "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
  # };

# e3591e1c-e091-4e16-b55f-088ab195fec4

  # mount /dev/sda1 /mnt
  # btrfs subvolume create /mnt/nix
  # btrfs subvolume create /mnt/nix/state
  # btrfs subvolume create /mnt/nix/state/home
  # mkdir -p /mnt/nix/state/var
  # btrfs subvolume create /mnt/nix/state/var/log

  # mkdir -p /nix/snaps
  # btrfs subvolume snapshot /nix/state /nix/snaps/state-$(date +%s)
  # btrfs subvolume snapshot /nix/state/home /nix/snaps/home-$(date +%s)


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

  # SabNZBd
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

  # persist.files = [ "/example.txt" ];

}
