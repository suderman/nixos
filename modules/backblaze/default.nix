# modules.backblaze = {
#   enable = true;
#   driveD = "/nix/state/home";
#   driveE = "/nix/state/var/lib";
#   driveF = "/mnt/ssd/data";
#   driveG = "/mnt/raid/media";
# };
{ inputs, config, lib, pkgs, this, ... }:
  
let 

  # https://github.com/JonathanTreffler/backblaze-personal-wine-container
  cfg = config.modules.backblaze;
  inherit (config.modules) traefik;
  inherit (lib) mkIf mkOption mkBefore types;

in {

  options.modules.backblaze = {
    enable = lib.options.mkEnableOption "backblaze"; 
    name = mkOption {
      type = types.str;
      default = "backblaze";
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/backblaze";
    };
    driveD = mkOption { type = types.str; default = "drive_d"; };
    driveE = mkOption { type = types.str; default = "drive_e"; };
    driveF = mkOption { type = types.str; default = "drive_f"; };
    driveG = mkOption { type = types.str; default = "drive_g"; };
  };

  config = mkIf cfg.enable {

    # Ensure data directory exists
    file."${cfg.dataDir}" = { type = "dir"; };

    # Docker container
    virtualisation.oci-containers.containers."backblaze" = {
      image = "tessypowder/backblaze-personal-wine:latest";
      autoStart = true;

      # Traefik labels
      extraOptions = traefik.labels [ cfg.name ]

      # Additional flags
      ++ [ "--init" ];

      # https://github.com/JonathanTreffler/backblaze-personal-wine-container#environment-variables
      environment = {
        DISPLAY_WIDTH = "660";
        DISPLAY_HEIGHT = "476";
        USER_ID = "0"; # run as root
        GROUP_ID = "0"; # run as root
        TZ = config.time.timeZone;
      };

      # Bind volumes
      volumes = [ 
        "${cfg.dataDir}:/config" 
        "${cfg.driveD}:/drive_d"
        "${cfg.driveE}:/drive_e"
        "${cfg.driveF}:/drive_f"
        "${cfg.driveG}:/drive_g"
      ];

    };

    # After installing Mono/Wine, stop at the email input and run:
    # > docker restart backblaze
    # This will ensure Backblaze can see the volumes/drive letters
    systemd.services.docker-backblaze = {
      postStart = let dir = "${cfg.dataDir}/wine/dosdevices"; in mkBefore ''
        while [ ! -d "${dir}" ]; do sleep 1; done
        [ -h "${dir}/d:" ] || ln -s /drive_d "${dir}/d:"
        [ -h "${dir}/e:" ] || ln -s /drive_e "${dir}/e:"
        [ -h "${dir}/f:" ] || ln -s /drive_f "${dir}/f:"
        [ -h "${dir}/g:" ] || ln -s /drive_g "${dir}/g:"
      '';
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

  }; 

}
