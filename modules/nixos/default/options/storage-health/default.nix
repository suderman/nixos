{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  cfg = config.services.storage-health;
  volumeType = lib.types.submodule ({name, ...}: {
    options = {
      mountPoint = lib.mkOption {
        type = lib.types.str;
        default =
          if name == "boot"
          then "/boot"
          else "/mnt/${name}";
      };
      devices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [config.fileSystems.${cfg.volumes.${name}.mountPoint}.device];
        description = "Expected logical backing devices. RAID enclosure members are not inspected.";
      };
      mounts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [cfg.volumes.${name}.mountPoint];
        description = "All mount/automount aliases to inhibit together. Include the sampling mount point.";
      };
      mountTimeoutSec = lib.mkOption {
        type = lib.types.ints.positive;
        default = 15;
        description = "Mount timeout for every quarantinable alias of this volume.";
      };
      startupGraceSec = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 0;
        description = "Seconds after boot to wait for initially absent devices. Device loss after detection still fails immediately.";
      };
      quarantine = lib.mkOption {
        type = lib.types.bool;
        default = name != "boot" && cfg.volumes.${name}.mountPoint != config.persist.path;
        description = "Mask mounts after device loss or read-only failure. Never enable for root storage.";
      };
      services = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Explicit dependent services to stop/inhibit after a hard failure.";
      };
    };
  });
  volumes = lib.mapAttrs (name: volume:
    volume
    // {
      fsType = config.fileSystems.${volume.mountPoint}.fsType;
      units =
        if volume.quarantine
        then
          (map (path: "${utils.escapeSystemdPath path}.automount") (lib.filter (path: lib.elem "x-systemd.automount" config.fileSystems.${path}.options) volume.mounts))
          ++ map (path: "${utils.escapeSystemdPath path}.mount") volume.mounts
        else [];
      jobs =
        ["storage-space-${name}.service"]
        ++ lib.mapAttrsToList (instance: _: "btrbk-${instance}.service")
        (lib.filterAttrs (_: instance: instance.onCalendar != null && instance.settings.volume ? ${volume.mountPoint}) config.services.btrbk.instances);
    })
  cfg.volumes;
  settings = pkgs.writeText "storage-health.json" (builtins.toJSON {
    inherit volumes;
    inherit (cfg) notifyURL desktopUser;
    host = config.networking.hostName;
    desktopUID =
      if cfg.desktopUser == null
      then null
      else config.users.users.${cfg.desktopUser}.uid;
  });
  command = pkgs.writeShellApplication {
    name = "storage-health";
    runtimeInputs = [pkgs.python3 pkgs.systemd pkgs.procps pkgs.util-linux pkgs.curl pkgs.libnotify];
    text = ''exec python3 ${./storage-health.py} ${settings} "$@"'';
  };
  bounded = {
    Type = "oneshot";
    UMask = "0077";
    MemoryMax = "192M";
    MemorySwapMax = 0;
    TasksMax = 32;
    CPUWeight = 20;
    IOWeight = 20;
    TimeoutStopSec = "5s";
  };
  services = lib.mkMerge (lib.mapAttrsToList (
      name: volume:
        lib.genAttrs (map (lib.removeSuffix ".service") volume.services) (_: {
          unitConfig.ConditionPathExists = ["!/run/storage-health/blocked/${name}"];
          unitConfig.RequiresMountsFor = [volume.mountPoint];
        })
    )
    cfg.volumes);
in {
  options.services.storage-health = {
    enable = lib.mkEnableOption "filesystem containment, cached MOTD and bounded pressure diagnostics";
    volumes = lib.mkOption {
      type = lib.types.attrsOf volumeType;
      default = lib.genAttrs (["boot"] ++ map builtins.baseNameOf (lib.attrNames config.services.btrbk.volumes)) (_: {});
    };
    notifyURL = lib.mkOption {
      type = lib.types.str;
      default = "https://ntfy.hub/storage";
    };
    desktopUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };
  config = lib.mkIf cfg.enable {
    assertions =
      lib.mapAttrsToList (name: volume: {
        assertion = builtins.match "[a-z0-9-]+" name != null && !(volume.quarantine && lib.elem "/" volume.mounts);
        message = "storage-health requires simple volume names and must not quarantine root mounts";
      })
      cfg.volumes;
    services.btrbk.isolateVolumes = true;
    # Bounds apply to every secondary mount alias, including bind mounts.
    fileSystems = lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (
        _: volume:
          map (path: lib.nameValuePair path {options = lib.mkAfter ["x-systemd.mount-timeout=${toString volume.mountTimeoutSec}s" "x-systemd.device-bound"];})
          (
            if volume.quarantine
            then volume.mounts
            else []
          )
      )
      cfg.volumes));
    environment.systemPackages = [command];
    systemd.tmpfiles.rules = [
      "d /run/storage-health 0700 root root -"
      "d /run/storage-health/blocked 0700 root root -"
      "d /run/storage-health-motd 0755 root root -"
    ];
    # Cached output only. Space sampling uses O_PATH to avoid waking automounts.
    programs.rust-motd.settings.filesystems = lib.mkForce {};
    systemd.services = lib.mkMerge [
      services
      {
        rust-motd.serviceConfig.TimeoutStartSec = "30s";
        storage-health = {
          description = "Check storage metadata and sustained resource stalls";
          serviceConfig =
            bounded
            // {
              ExecStart = "${command}/bin/storage-health check";
              TimeoutStartSec = "12s";
              MemoryMax = "128M";
            };
        };
        storage-health-capture = {
          description = "Save a bounded diagnostic bundle to tmpfs";
          serviceConfig =
            bounded
            // {
              ExecStart = "${command}/bin/storage-health capture";
              TimeoutStartSec = "75s";
            };
        };
        storage-health-notify = {
          description = "Send pending storage-health alert through ntfy and optional desktop DBus";
          serviceConfig =
            bounded
            // {
              ExecStart = "${command}/bin/storage-health notify";
              TimeoutStartSec = "30s";
            };
        };
      }
      (lib.mapAttrs' (name: _:
        lib.nameValuePair "storage-space-${name}" {
          description = "Cache ${name} space only while already mounted and healthy";
          unitConfig.ConditionPathExists = "!/run/storage-health/blocked/${name}";
          serviceConfig =
            bounded
            // {
              ExecStart = "${command}/bin/storage-health sample ${name}";
              TimeoutStartSec = "10s";
              MemoryMax = "64M";
            };
        })
      volumes)
    ];
    systemd.timers =
      {
        storage-health = {
          wantedBy = ["timers.target"];
          timerConfig = {
            OnBootSec = "15s";
            OnUnitInactiveSec = "15s";
            AccuracySec = "1s";
          };
        };
      }
      // lib.mapAttrs' (name: _:
        lib.nameValuePair "storage-space-${name}" {
          wantedBy = ["timers.target"];
          timerConfig = {
            OnBootSec = "45s";
            OnUnitInactiveSec = "5min";
            AccuracySec = "10s";
          };
        })
      volumes;
  };
}
