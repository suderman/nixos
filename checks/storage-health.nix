{
  flake,
  pkgs,
  ...
}: let
  lib = pkgs.lib;
  module = ../modules/nixos/default/options/storage-health;
  hosts = map (host: flake.nixosConfigurations.${host}.config) ["kit" "lux" "pow" "eve"];
  cfg = flake.nixosConfigurations.kit.config;
  units = cfg.systemd.services;
  verify = config: let
    jobs = lib.filterAttrs (_: instance: instance.onCalendar != null) config.services.btrbk.instances;
    snapshots = lib.filterAttrs (name: _: lib.hasPrefix "snapshots-" name) jobs;
    backups = lib.filterAttrs (name: _: lib.hasPrefix "backups-" name) jobs;
    expectedTargets = lib.concatLists (lib.attrValues config.services.btrbk.volumes);
    actualTargets = lib.concatLists (lib.mapAttrsToList (_: instance: lib.attrNames (builtins.head (lib.attrValues instance.settings.volume)).target) backups);
  in
    config.services.storage-health.enable
    && config.services.btrbk.isolateVolumes
    && config.services.btrbk.instances.snapshots.onCalendar == null
    && config.services.btrbk.instances.backups.onCalendar == null
    && lib.length (lib.attrNames snapshots) == lib.length (lib.attrNames config.services.btrbk.volumes)
    && builtins.sort builtins.lessThan actualTargets == builtins.sort builtins.lessThan expectedTargets
    && config.programs.rust-motd.settings.filesystems == {}
    && lib.all (instance: lib.length (lib.attrNames instance.settings.volume) == 1) (lib.attrValues jobs)
    && lib.all (name: config.systemd.services."btrbk-${name}".serviceConfig.Slice == "btrbk.slice") (lib.attrNames jobs)
    && lib.all (name: config.systemd.services."btrbk-${name}".serviceConfig ? ExecStartPre) (lib.attrNames jobs)
    && lib.all (volume:
      lib.all (path:
        lib.all (option: lib.elem option config.fileSystems.${path}.options)
        ["x-systemd.mount-timeout=15s" "x-systemd.device-bound"])
      volume.mounts)
    (lib.attrValues (lib.filterAttrs (_: volume: volume.quarantine) config.services.storage-health.volumes));
in
  assert lib.all verify hosts;
  assert !(cfg.services.btrbk.volumes ? "/mnt/game");
  assert cfg.services.storage-health.volumes.data.mounts == ["/mnt/data" "/data" "/home/jon/data"];
  assert units.btrbk-snapshots-data.serviceConfig.TimeoutStartSec == "10min";
  assert units.btrbk-backups-data-0.serviceConfig.TimeoutStartSec == "6h";
  assert units.storage-health.serviceConfig.MemorySwapMax == 0;
  assert units.storage-health-capture.serviceConfig.TimeoutStartSec == "75s";
  assert units.storage-space-data.serviceConfig.TimeoutStartSec == "10s";
  assert lib.length flake.nixosConfigurations.pow.config.services.storage-health.volumes.pool.devices == 2;
  assert lib.length flake.nixosConfigurations.eve.config.services.storage-health.volumes.pool.devices == 2;
  assert lib.length flake.nixosConfigurations.lux.config.services.storage-health.volumes.pool.devices == 1;
  assert lib.length flake.nixosConfigurations.lux.config.systemd.services.docker-backblaze.unitConfig.ConditionPathExists == 2;
  assert !flake.nixosConfigurations.cog.config.services.storage-health.enable;
    pkgs.runCommand "storage-health-check" {nativeBuildInputs = [pkgs.python3];} ''
      export PYTHONDONTWRITEBYTECODE=1
      python ${module}/test_storage_health.py
      touch "$out"
    ''
