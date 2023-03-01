{ inputs, config, lib, pkgs, ... }: {

  imports = [
    ./hardware-configuration.nix
  ];

  fileSystems."/".options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" "subvol=root" ];
  fileSystems."/nix".options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ];

  # boot.initrd.postDeviceCommands = lib.mkBefore ''
  #   btrfs subvolume list -o /nix/root |
  #   cut -f9 -d' ' |
  #   while read subvolume; do
  #     echo "deleting /$subvolume subvolume..."
  #     btrfs subvolume delete "/nix/$subvolume"
  #   done &&
  #
  #   echo "deleting /root subvolume..." &&
  #   btrfs subvolume delete /nix/root
  #
  #   echo "restoring blank /root subvolume..."
  #   btrfs subvolume snapshot /nix/snaps/root /nix/root
  # '';

  boot.initrd.postDeviceCommands = lib.mkBefore ''
    # Mount btrfs disk to /mnt
    mkdir -p /mnt
    mount /dev/disk/by-label/Butter /mnt

    # Delete all of root's subvolumes
    btrfs subvolume list -o /mnt/root |
    cut -f9 -d' ' |
    while read subvolume; do
      echo "deleting /$subvolume subvolume..."
      btrfs subvolume delete "/mnt/$subvolume"
    done &&

    # Delete root itself
    echo "deleting /root subvolume..." &&
    btrfs subvolume delete /mnt/root

    # Restore root from blank snapshot
    echo "restoring blank /root subvolume..."
    btrfs subvolume snapshot /mnt/snaps/root /mnt/root

    # Clean up
    umount /mnt
  '';

  base.enable = true;
  state.enable = true;
  secrets.enable = true;

  # Hardware configuration
  hardware.linode.enable = true;

  # Network
  services.tailscale.enable = true;
  services.ddns.enable = true;
  services.openssh.enable = true;
  networking.extraHosts = "";

  # Memory management
  services.earlyoom.enable = true;

  # Database services
  services.mysql.enable = true;
  services.postgresql.enable = false;

  # Web services
  services.traefik.enable = true;
  services.whoogle.enable = false;
  services.whoami.enable = true;
  services.sabnzbd.enable = false;
  services.tandoor-recipes.enable = false;
  # services.gitea.enable = true;
  # services.gitea.database.type = "mysql";

  # Apps
  programs.mosh.enable = true;
  programs.neovim.enable = true;
  programs.tmux.enable = true;

}
