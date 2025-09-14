{
  config,
  lib,
  flake,
  ...
}: let
  inherit (builtins) mapAttrs;
  inherit (lib) mkAfter mkOption types unique;
  users = config.home-manager.users or {};
in {
  # Import impermanence module
  imports = [flake.inputs.impermanence.nixosModule];

  # Extra options
  options.persist = {
    enable = mkOption {
      description = "Enable persistent storage location";
      type = types.bool;
      default = true;
      example = false;
    };

    # Files relative to / root
    storage.files = mkOption {
      description = "System files to persist reboots and snapshot";
      type = with types; listOf (either str attrs);
      default = [];
      example = ["/etc/machine-id"];
    };

    # Directories relative to / root
    storage.directories = mkOption {
      description = "System directories to persist reboots and snapshot";
      type = with types; listOf (either str attrs);
      default = [];
      example = ["/etc/nixos"];
    };

    # Files relative to / root
    scratch.files = mkOption {
      description = "System files to persist reboots";
      type = with types; listOf (either str attrs);
      default = [];
      example = ["/etc/machine-id"];
    };

    # Directories relative to / root
    scratch.directories = mkOption {
      description = "System directories to persist reboots";
      type = with types; listOf (either str attrs);
      default = [];
      example = ["/etc/nixos"];
    };
  };

  config = {
    # Persist reboots only
    environment.persistence."/mnt/main/scratch" = {
      inherit (config.persist) enable;
      hideMounts = true;

      # System directories
      directories = unique ([
          "/var/log"
        ]
        ++ config.persist.scratch.directories);

      # System files
      files = unique config.persist.scratch.files;

      # Persist user data
      users =
        mapAttrs (_: user: {
          directories = unique user.persist.scratch.directories;
          files = unique user.persist.scratch.files;
        })
        users;
    };

    # Persist reboots with snapshots and backups
    environment.persistence."/mnt/main/storage" = {
      inherit (config.persist) enable;
      hideMounts = true;

      # System directories
      directories = unique ([
          "/etc/nixos"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
        ]
        ++ config.persist.storage.directories);

      # System files
      files = unique config.persist.storage.files;

      # Persist user data
      users =
        mapAttrs (_: user: {
          # User directories
          directories = unique ([
              "Downloads"
            ]
            ++ user.persist.storage.directories);

          # User files
          files = unique ([
              ".bashrc"
            ]
            ++ user.persist.storage.files);
        })
        users;
    };

    # Persistent volumes must be marked with neededForBoot
    fileSystems."/mnt/main".neededForBoot = true;

    # Allows users to allow others on their binds
    programs.fuse.userAllowOther = true;

    # Script to wipe the root subvolume at boot
    boot.initrd.postResumeCommands =
      mkAfter
      # bash
      ''
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
