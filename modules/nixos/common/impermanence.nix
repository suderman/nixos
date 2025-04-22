{ config, inputs, lib, ... }: let

  cfg = config.state;
  inherit (lib) mkAfter mkOption types;

in {

  # Import impermanence module
  imports = [ inputs.impermanence.nixosModule ];

  # Extra options
  options.state = {

    # Files relative to / root
    files = mkOption {
      description = "System files to preserve";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ "/etc/machine-id" ];
    };

    # Directories relative to / root
    dirs = mkOption {
      description = "System directories to preserve";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ "/etc/nixos" ];
    };

  };

  config = {

    # Configuration impermanence module
    environment.persistence."/persist" = {

      hideMounts = true;

      # System files
      files = cfg.files;

      # System directories
      directories = [
        # "/etc/nixos"
        "/etc/NetworkManager/system-connections"
        # "/var/lib"  
        "/var/lib/nixos"
        "/var/log"  
        "/var/lib/systemd/coredump"
        # "/home"  
      ] ++ cfg.dirs;

    };

    # Persistent volumes must be marked with neededForBoot
    fileSystems."/persist".neededForBoot = true;

    # Allows users to allow others on their binds
    programs.fuse.userAllowOther = true;

    # # Script to wipe the root subvolume at boot
    # boot.initrd.postResumeCommands = mkAfter ''
    #   # Mount btrfs disk to /mnt
    #   mkdir -p /mnt
    #   mount /dev/disk/by-label/root /mnt
    #
    #   # Check if root subvolume exists
    #   if btrfs subvolume show /mnt/root &>/dev/null; then
    #
    #     # Delete all of root's subvolumes
    #     btrfs subvolume list -o /mnt/root |
    #     cut -f9 -d' ' |
    #     while read subvolume; do
    #       btrfs subvolume delete "/mnt/$subvolume"
    #     done
    #
    #     # Delete root itself
    #     btrfs subvolume delete /mnt/root
    #
    #   fi
    #
    #   # Create a new blank subvolume at the same path
    #   btrfs subvolume create /mnt/root
    #
    #   # Clean up
    #   umount /mnt
    # '';

  };

}
