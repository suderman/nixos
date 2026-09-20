{
  config,
  lib,
  flake,
  ...
}: let
  inherit (builtins) attrNames baseNameOf mapAttrs;
  inherit (lib) genAttrs mkOption mkMerge types unique;
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

    path = mkOption {
      description = "Path to main mount";
      type = types.str;
      default = "/mnt/main"; # needed for boot
    };

    storage.path = mkOption {
      description = "Path to storage directory";
      type = types.str;
      default = "${config.persist.path}/storage";
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

    scratch.path = mkOption {
      description = "Path to scratch directory";
      type = types.str;
      default = "${config.persist.path}/scratch";
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
    environment.persistence."${config.persist.scratch.path}" = {
      inherit (config.persist) enable;
      hideMounts = true;

      # System directories
      directories = unique ([
          "/var/log"
          "/var/lib/systemd/coredump"
        ]
        ++ config.persist.scratch.directories);

      # System files
      files = unique config.persist.scratch.files;

      # Persist user data
      users =
        mapAttrs (_: user: {
          directories = unique ([
              ".scratch"
            ]
            ++ user.persist.scratch.directories);
          files = unique user.persist.scratch.files;
        })
        users;
    };

    # Persist reboots with snapshots and backups
    environment.persistence."${config.persist.storage.path}" = {
      inherit (config.persist) enable;
      hideMounts = true;

      # System directories
      directories = unique ([
          "/etc/nixos"
          "/var/lib/nixos"
        ]
        ++ config.persist.storage.directories);

      # System files
      files = unique config.persist.storage.files;

      # Persist user data
      users =
        mapAttrs (_: user: {
          directories = unique ([
              ".storage"
              ".ssh"
            ]
            ++ user.persist.storage.directories);
          files = unique ([
              ".bashrc"
              ".bash_history"
            ]
            ++ user.persist.storage.files);
        })
        users;
    };

    fileSystems = let
      # List of all non-hidden user dirs
      userDirs = type:
        map (x: x.dirPath)
        (builtins.filter (d: builtins.substring 0 1 d.directory != "." && d.home != null)
          config.environment.persistence."${config.persist."${type}".path}".directories);
    in
      mkMerge [
        # Support trash in these bind mounts
        (
          genAttrs
          ((userDirs "scratch") ++ (userDirs "storage"))
          (_: {options = ["x-gvfs-trash"];})
        )

        # Persistent volumes must be marked with neededForBoot
        {"${config.persist.path}".neededForBoot = true;}
      ];

    # Allows users to allow others on their binds
    programs.fuse.userAllowOther = true;

    # Ensure directory structure
    tmpfiles.directories = [
      {
        target = "/var/lib/private";
        mode = "0700";
      }
    ];

    # Wipe the root subvolume after resume and before mounting it.
    boot.initrd.systemd.services.reset-root = {
      description = "Reset Btrfs root subvolume";
      requiredBy = ["sysroot.mount"];
      after = [
        "initrd-root-device.target"
        "local-fs-pre.target"
      ];
      before = ["sysroot.mount"];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        # Keep the unit active so initrd shutdown cannot start the reset again.
        RemainAfterExit = true;
      };
      script =
        # bash
        ''
          cleanup() {
            status=$?
            trap - EXIT
            if ! umount /mnt; then
              echo "Failed to unmount temporary Btrfs mount /mnt" >&2
              ((status != 0)) || status=1
            fi
            exit "$status"
          }

          mkdir -p /mnt
          mount -t btrfs -o subvolid=5 ${lib.escapeShellArg config.fileSystems."${config.persist.path}".device} /mnt
          trap cleanup EXIT

          # Refuse to operate anywhere except the configured Btrfs top level.
          test "$(btrfs inspect-internal rootid /mnt)" = 5

          if test -e /mnt/root; then
            test ! -L /mnt/root
            btrfs subvolume show /mnt/root >/dev/null
            btrfs subvolume delete --commit-after --recursive /mnt/root
          fi

          btrfs subvolume create /mnt/root
          mkdir -p /mnt/root/var/log /mnt/root/var/lib/nixos
        '';
    };
  };
}
