# config.programs.steam.enable = true;
{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.programs.steam;
  inherit (lib) mkIf options;
  dataDir = ".local/share/Steam"; # steam expects this path
in {
  options.programs.steam.enable = options.mkEnableOption "steam";
  config = mkIf cfg.enable {
    # Persist data directory Steam uses
    persist.scratch.directories = [dataDir];

    # Timer to run backup script daily
    systemd.user.timers.steam-backup = {
      Unit.Description = "Run Steam backup daily";
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };

    # Backup script to copy select backup file from scratch to storage
    systemd.user.services.steam-backup = {
      Unit.Description = "Backup Steam config, userdata, and local.vdf";
      Service = {
        Type = "oneshot";
        ExecStart = perSystem.self.mkScript {
          path = [pkgs.coreutils pkgs.rsync];
          env = {
            SCRATCH = "${config.persist.scratch.path}/${dataDir}";
            STORAGE = "${config.persist.storage.path}/${dataDir}";
          };
          text =
            # bash
            ''
              # Ensure storage dir exists
              mkdir -p "$STORAGE"

              # Backup userdata dir
              [[ -d "$SCRATCH/userdata" ]] && \
                rsync -a --delete \
                  "$SCRATCH/userdata/" \
                  "$STORAGE/userdata/"

              # Backup config dir
              [[ -d "$SCRATCH/config" ]] && \
                rsync -a --delete \
                  --exclude 'htmlcache' \
                  --exclude 'cefdata' \
                  --exclude 'avatarcache' \
                  "$SCRATCH/config/" \
                  "$STORAGE/config/"

              # Backup login file
              [[ -f "$SCRATCH/local.vdf" ]] && \
                rsync -a --delete \
                  "$SCRATCH/local.vdf" \
                  "$STORAGE/"
            '';
        };
      };
    };
  };
}
