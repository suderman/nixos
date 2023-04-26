# modules.backblaze.enable = true;
{ inputs, config, pkgs, lib, ... }:
  
let 

  # https://github.com/JonathanTreffler/backblaze-personal-wine-container
  cfg = config.modules.backblaze;
  inherit (lib) mkIf mkOption mkBefore types;

in {

  options.modules.backblaze = {
    enable = lib.options.mkEnableOption "backblaze"; 
    hostName = mkOption {
      type = types.str;
      default = "backblaze.${config.networking.fqdn}";
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/backblaze";
    };
    runDir = mkOption {
      type = types.path;
      default = "/run/backblaze";
    };
    backupDir = mkOption {
      type = types.path;
      default = "/home";
    };
  };

  config = mkIf cfg.enable {

    # Randomly chose unused id from here:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.backblaze = 199;
    ids.gids.backblaze = 199;

    users.users.backblaze = {
      isSystemUser = true;
      group = "backblaze";
      description = "Backblaze daemon user";
      home = "${cfg.dataDir}";
      uid = config.ids.uids.backblaze;
    };

    users.groups.backblaze = {
      gid = config.ids.gids.backblaze;
    };

    virtualisation.oci-containers.containers."backblaze" = {
      image = "tessypowder/backblaze-personal-wine";
      autoStart = true;

      # Traefik labels
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.backblaze.rule=Host(`${cfg.hostName}`)"
        "--label=traefik.http.routers.backblaze.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.backblaze.middlewares=local@file"

      # Additional flags
      ] ++ [
        "--init"
      ];

      # https://github.com/JonathanTreffler/backblaze-personal-wine-container#environment-variables
      environment = {
        DISPLAY_WIDTH = "660";
        DISPLAY_HEIGHT = "476";
        USER_ID = toString config.users.users.backblaze.uid;
        GROUP_ID = toString config.users.groups.backblaze.gid;
        TZ = config.time.timeZone;
      };

      # Bind volumes
      volumes = [ 
        "${cfg.dataDir}:/config" 
        "${cfg.runDir}:/drive_d"
        "${cfg.backupDir}:/drive_d/data"
      ];

    };

    systemd.services.docker-backblaze = {
      preStart = let
        uid = toString config.users.users.backblaze.uid;
        gid = toString config.users.groups.backblaze.gid;
      in mkBefore ''
        mkdir -p ${cfg.runDir}
        chown ${uid}:${gid} ${cfg.runDir}
        [ -e ${cfg.runDir}/.bzvol ] && chown -R ${uid}:${gid} ${cfg.runDir}/.bzvol
      '';
      # serviceConfig.BindPaths = [ "${cfg.backupDir}:${cfg.runDir}/data" ];
    };

    # # Container will not stop gracefully, so kill it
    # systemd.services.docker-backblaze.serviceConfig = {
    #   KillSignal = "SIGKILL";
    #   SuccessExitStatus = "0 SIGKILL";
    # };

    # After installing Mono/Wine, stop at the email input and instead run:
    # sudo backblaze-add-storage
    # ...once the container reloads, head back in and enter your email address.
    environment.systemPackages = [( 
      pkgs.writeShellScriptBin "backblaze-add-storage" ''
        #!/usr/bin/env bash
        docker exec --user app backblaze ln -s /drive_d/ /config/wine/dosdevices/d:
        docker restart backblaze
      ''
    )];

    # Enable reverse proxy
    modules.traefik.enable = true;

  }; 

}
