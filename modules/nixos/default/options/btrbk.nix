{
  config,
  lib,
  pkgs,
  perSystem,
  flake,
  ...
}: let
  cfg = config.services.btrbk;
  inherit (lib) mkAfter mkIf mkOption types;

  # Path to private and public ssh key
  sshKey = "/etc/btrbk/id_ed25519";
  sshPubKey = flake + /users/btrbk/id_ed25519.pub;

  # Enable if there are any volumes set (default true)
  enable = builtins.length (builtins.attrNames cfg.volumes) > 0;
in {
  options.services.btrbk.volumes = mkOption {
    type = types.attrs;
    default = {
      "${config.persist.path}" = [];
    };
    example = {
      "${config.persist.path}" = ["ssh://eve/mnt/pool/backups/${config.networking.hostName}"];
    };
  };

  # Use btrbk to snapshot persistent states and home
  config = mkIf enable {
    services.btrbk.sshAccess = [
      {
        key = builtins.readFile sshPubKey;
        roles = ["info" "source" "target" "delete" "snapshot" "send" "receive"];
      }
    ];

    # Extra packages for btrbk
    environment.systemPackages = [pkgs.lz4 pkgs.mbuffer];

    services.btrbk.instances = let
      shared = {
        timestamp_format = "long";
        preserve_day_of_week = "monday";
        preserve_hour_of_day = "23";
        stream_buffer = "256m";
        snapshot_dir = "snapshots";
        ssh_user = "btrbk";
        ssh_identity = sshKey;
      };
    in {
      # All snapshots are retained for at least 6 hours regardless of other policies.
      "snapshots" = {
        onCalendar = "*:00";
        settings =
          shared
          // {
            snapshot_create = "onchange";
            snapshot_preserve_min = "6h";
            snapshot_preserve = "48h 7d 4w";
            volume =
              builtins.mapAttrs (path: _targets: {
                subvolume.storage.snapshot_name = builtins.baseNameOf path;
              })
              cfg.volumes;
          };
      };

      # Send snapshots to backup targets (none declared here) at 12:15 every night.
      "backups" = {
        onCalendar = "00:15";
        settings =
          shared
          // {
            stream_compress = "lz4";
            snapshot_create = "no";
            snapshot_preserve_min = "all";
            target_preserve_min = "1d";
            target_preserve = "7d 4w 6m";
            volume =
              builtins.mapAttrs (path: targets: {
                subvolume.storage.snapshot_name = builtins.baseNameOf path;
                target = builtins.listToAttrs (map (t: {
                    name = t;
                    value = {};
                  })
                  targets);
              })
              cfg.volumes;
          };
      };
    };

    # Point default btrbk.conf to backup config
    environment.etc."btrbk.conf".source = "/etc/btrbk/backups.conf";

    # Write btrbk ssh keys to /etc/btrbk
    system.activationScripts.users.text = let
      inherit (perSystem.self) mkScript;
      hex = config.age.secrets.hex.path;

      # Derive ssh key for btrbk user
      text =
        # bash
        ''
          mkdir -p $(dirname ${sshKey})
          cd $(dirname ${sshKey})

          # Copy public ssh user key from this repo
          cat ${sshPubKey} > ${sshKey}.pub

          # Derive private ssh user key and verify
          if [[ -f ${hex} ]]; then
            derive hex btrbk <${hex} |
            derive ssh >${sshKey}
            sshed verify || rm -f ${sshKey}
          fi

          # Ensure proper permissions and ownership
          [[ -f ${sshKey} ]] && chmod 600 ${sshKey}
          [[ -f ${sshKey}.pub ]] && chmod 644 ${sshKey}.pub
          chown btrbk:btrbk ${sshKey}*
        '';

      path = [perSystem.self.derive perSystem.self.sshed];
    in
      mkAfter "${mkScript {inherit text path;}}";
  };
}
