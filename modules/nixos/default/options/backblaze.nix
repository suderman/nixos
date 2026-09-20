# services.backblaze = {
#   enable = true;
#   driveD = "/nix/state/home";
#   driveE = "/nix/state/var/lib";
#   driveF = "/mnt/ssd/data";
#   driveG = "/mnt/raid/media";
# };
{
  config,
  flake,
  lib,
  ...
}: let
  # https://github.com/JonathanTreffler/backblaze-personal-wine-container
  cfg = config.services.backblaze;
  inherit (config.services.traefik.lib) mkLabels;
  inherit (lib) mkIf mkOption types;
in {
  options.services.backblaze = {
    enable = lib.options.mkEnableOption "backblaze";
    name = mkOption {
      type = types.str;
      default = "backblaze";
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/backblaze";
    };
    autoUpdate = mkOption {
      type = types.bool;
      default = false;
    };
    driveD = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    driveE = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    driveF = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    driveG = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    # Ensure data directory exists and is persisted
    tmpfiles.directories = [cfg.dataDir];
    persist.storage.directories = [cfg.dataDir];

    # Docker container
    virtualisation.oci-containers.containers."backblaze" = {
      image = flake.inputs.pins.default.containers.backblaze-personal-wine.image;
      autoStart = true;

      # Traefik labels
      extraOptions =
        mkLabels [cfg.name]
        # Additional flags
        ++ ["--init"];

      # https://github.com/JonathanTreffler/backblaze-personal-wine-container#environment-variables
      environment = {
        USER_ID = "0"; # run as root
        GROUP_ID = "0"; # run as root
        DISABLE_AUTOUPDATE = lib.boolToString (!cfg.autoUpdate);
        TZ = config.time.timeZone;
      };

      # Bind volumes
      volumes =
        ["${cfg.dataDir}:/config"]
        ++ lib.optional (cfg.driveD != null) "${cfg.driveD}:/drive_d"
        ++ lib.optional (cfg.driveE != null) "${cfg.driveE}:/drive_e"
        ++ lib.optional (cfg.driveF != null) "${cfg.driveF}:/drive_f"
        ++ lib.optional (cfg.driveG != null) "${cfg.driveG}:/drive_g";
    };

    systemd.services.docker-backblaze.unitConfig.RequiresMountsFor = [cfg.dataDir];

    # Enable reverse proxy
    services.traefik.enable = true;
  };
}
