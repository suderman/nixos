{
  config,
  lib,
  pkgs,
  perSystem,
  utils,
  flake,
  ...
}: let
  cfg = config.services.btrbk;
  inherit (lib) mkAfter mkIf mkOption types;
  inherit (flake.lib) identityRotation;

  # Path to private and public ssh key
  sshKey = "/etc/btrbk/id_ed25519";
  sshPubKey = flake + /users/btrbk/id_ed25519.pub;
  nextSshKey = "${sshKey}.next";
  nextSshPubKey = identityRotation.nextPath sshPubKey;

  # Enable if there are any volumes set (default true)
  enable = builtins.length (builtins.attrNames cfg.volumes) > 0;
in {
  options.services.btrbk.isolateVolumes = lib.mkEnableOption "independent bounded snapshot sources and backup destinations";
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
    services.btrbk.sshAccess =
      map (publicKey: {
        key = builtins.readFile publicKey;
        roles = ["info" "source" "target" "delete" "snapshot" "send" "receive"];
      })
      (identityRotation.keyFiles [sshPubKey]);

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
        ssh_identity =
          if identityRotation.useNext
          then nextSshKey
          else sshKey;
      };
      split = lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (path: targets: let
        name = builtins.baseNameOf path;
        volume = {"${path}".subvolume.storage.snapshot_name = name;};
      in
        [
          (lib.nameValuePair "snapshots-${name}" {
            onCalendar = "*:00";
            settings =
              shared
              // {
                snapshot_create = "onchange";
                snapshot_preserve_min = "6h";
                snapshot_preserve = "48h 7d 4w";
                inherit volume;
              };
          })
        ]
        ++ lib.imap0 (index: target:
          lib.nameValuePair "backups-${name}-${toString index}" {
            onCalendar = "00:15";
            settings =
              shared
              // {
                stream_compress = "lz4";
                snapshot_create = "no";
                snapshot_preserve_min = "all";
                target_preserve_min = "1d";
                target_preserve = "7d 4w 6m";
                volume = {"${path}" = volume.${path} // {target.${target} = {};};};
              };
          })
        targets)
      cfg.volumes));
    in
      (lib.optionalAttrs cfg.isolateVolumes split)
      // {
        # All snapshots are retained for at least 6 hours regardless of other policies.
        "snapshots" = {
          onCalendar =
            if cfg.isolateVolumes
            then null
            else "*:00";
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
          onCalendar =
            if cfg.isolateVolumes
            then null
            else "00:15";
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

    # Oct 3, 2026: one failed source/destination must not hold unrelated backups.
    systemd.services = lib.mkIf cfg.isolateVolumes (lib.mapAttrs' (name: instance: let
      path = builtins.head (builtins.attrNames instance.settings.volume);
      volumeName = builtins.baseNameOf path;
      hosts = "{" + lib.concatStringsSep "," (builtins.attrNames flake.nixosConfigurations) + "}";
      directories = pkgs.writeShellScript "btrbk-directories-${volumeName}" ''
        set -e
        ${pkgs.systemd}/bin/systemctl start ${lib.escapeShellArg "${utils.escapeSystemdPath path}.mount"}
        exec ${pkgs.coreutils}/bin/mkdir -p ${path}/backups/${hosts}
      '';
    in
      lib.nameValuePair "btrbk-${name}" {
        unitConfig.ConditionPathExists = "!/run/storage-health/blocked/${volumeName}";
        serviceConfig = {
          Slice = "btrbk.slice";
          TimeoutStartSec =
            if lib.hasPrefix "snapshots-" name
            then "10min"
            else "6h";
          TimeoutStopSec = "15s";
          MemoryMax = "1G";
          MemorySwapMax = "128M";
          TasksMax = 128;
          CPUWeight = 20;
          IOWeight = 20;
          # Mount only after ConditionPathExists passes. RequiresMountsFor would
          # queue mount dependencies before the failed-volume guard is checked.
          # Directory setup belongs to the bounded job, not system activation.
          ExecStartPre = ["+${directories}"];
        };
      }) (lib.filterAttrs (_: instance: instance.onCalendar != null) cfg.instances));
    systemd.slices.btrbk = lib.mkIf cfg.isolateVolumes {
      sliceConfig = {
        MemoryHigh = "1G";
        MemoryMax = "2G";
        MemorySwapMax = "128M";
        TasksMax = 256;
        CPUWeight = 20;
        IOWeight = 20;
      };
    };
    programs.ssh.extraConfig = lib.mkIf cfg.isolateVolumes (lib.mkAfter ''
      Match user btrbk
        BatchMode yes
        ConnectTimeout 10
        ServerAliveInterval 15
        ServerAliveCountMax 2
      Match all
    '');

    # Point default btrbk.conf to backup config
    environment.etc."btrbk.conf".source = "/etc/btrbk/backups.conf";

    # Create backups directories per host
    system.activationScripts.backups.text = let
      inherit (builtins) attrNames concatStringsSep;
      disks = attrNames config.services.btrbk.volumes;
      hosts = "{" + (concatStringsSep "," (attrNames flake.nixosConfigurations)) + "}";
    in
      if cfg.isolateVolumes
      then ""
      else concatStringsSep "\n" (map (dir: "mkdir -p ${dir}/backups/${hosts}") disks);

    # Write btrbk ssh keys to /etc/btrbk
    system.activationScripts.users.text = let
      inherit (perSystem.self) mkScript;
      inherit (config.identityRotation) currentHexPath nextHexPath;

      # Derive ssh key for btrbk user
      text =
        # bash
        ''
          mkdir -p $(dirname ${sshKey})
          cd $(dirname ${sshKey})

          # Copy public ssh user key from this repo
          cat ${sshPubKey} > ${sshKey}.pub

          write_btrbk_identity() {
            local root="$1" private_key="$2" public_key="$3"
            derive hex btrbk <"$root" | derive ssh >"$private_key"
            sshed verify-pair "$private_key" "$public_key"
          }

          # Derive private ssh user key and verify
          if [[ -f ${currentHexPath} ]]; then
            write_btrbk_identity ${currentHexPath} ${sshKey} ${sshKey}.pub
          fi

          ${lib.optionalString identityRotation.active ''
            cat ${nextSshPubKey} >${nextSshKey}.pub
            test -f ${nextHexPath}
            write_btrbk_identity ${nextHexPath} ${nextSshKey} ${nextSshKey}.pub
          ''}
          ${lib.optionalString (!identityRotation.active) ''
            rm -f ${nextSshKey} ${nextSshKey}.pub
          ''}

          # Ensure proper permissions and ownership
          [[ -f ${sshKey} ]] && chmod 600 ${sshKey}
          [[ -f ${sshKey}.pub ]] && chmod 644 ${sshKey}.pub
          [[ -f ${nextSshKey} ]] && chmod 600 ${nextSshKey}
          [[ -f ${nextSshKey}.pub ]] && chmod 644 ${nextSshKey}.pub
          chown btrbk:btrbk ${sshKey}*
        '';

      path = [perSystem.self.derive perSystem.self.sshed];
    in
      mkAfter "${mkScript {inherit text path;}}";
  };
}
