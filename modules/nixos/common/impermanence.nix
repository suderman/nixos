{ config, inputs, lib, ... }: let

  cfg = config.persist;
  inherit (builtins) baseNameOf mapAttrs;
  inherit (lib) mkAfter mkOption optionals types unique;
  users = config.home-manager.users or {};

in {

  # Import impermanence module
  imports = [ inputs.impermanence.nixosModule ];

  # Extra options
  options.persist = {

    # Default is enabled
    enable = mkOption {
      description = "Enable persistent storage location";
      type = types.bool;
      default = true;
      example = false;
    };

    # Files relative to / root
    files = mkOption {
      description = "System files to persist reboots and snapshot";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ "/etc/machine-id" ];
    };

    # Files relative to / root
    localFiles = mkOption {
      description = "System files to persist reboots";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ "/etc/machine-id" ];
    };

    # Directories relative to / root
    directories = mkOption {
      description = "System directories to persist reboots and snapshot";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ "/etc/nixos" ];
    };

    # Directories relative to / root
    localDirectories = mkOption {
      description = "System directories to persist reboots";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ "/etc/nixos" ];
    };

  };

  config = {

    # Persist reboots with snapshots and backups
    environment.persistence."/persist" = {
      enable = cfg.enable;
      hideMounts = true;

      # System directories
      directories = unique ([
        "/etc/nixos"
        "/etc/NetworkManager/system-connections"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
      ] ++ cfg.directories);

      # System files
      files = cfg.files;

      # Persist user data
      users = mapAttrs (name: user: {

        # User directories
        directories = unique ([
          "Downloads"
        ] ++ user.persist.directories);

        # User files
        files = unique ([
          ".bashrc"
        ] ++ user.persist.files);

      }) users; 

    };

    # Persist reboots only
    environment.persistence."/persist/local" = {
      enable = cfg.enable;
      hideMounts = true;

      # System directories
      directories = unique ([
        "/var/log"  
      ] ++ cfg.localDirectories);

      # System files
      files = unique cfg.localFiles;

      # Persist user data
      users = mapAttrs (name: user: {
        directories = unique user.persist.localDirectories;
        files = unique user.persist.localFiles;
      }) users; 

    };

    # Persistent volumes must be marked with neededForBoot
    fileSystems."/persist".neededForBoot = true;
    fileSystems."/persist/local".neededForBoot = true;

    # Allows users to allow others on their binds
    programs.fuse.userAllowOther = true;

    # Script to wipe the root subvolume at boot
    boot.initrd.postResumeCommands = mkAfter ''
      # Mount btrfs disk to /mnt
      mkdir -p /mnt
      mount /dev/disk/by-label/main /mnt

      # Check if root subvolume exists
      if btrfs subvolume show /mnt/root &>/dev/null; then

        # Delete all of root's subvolumes
        btrfs subvolume list -o /mnt/root |
        cut -f9 -d' ' |
        while read subvolume; do
          btrfs subvolume delete "/mnt/$subvolume"
        done

        # Delete root itself
        btrfs subvolume delete /mnt/root

      fi

      # Create a new blank subvolume at the same path
      btrfs subvolume create /mnt/root

      # Clean up
      umount /mnt
    '';

  };

}
