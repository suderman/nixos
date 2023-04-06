{ config, lib, pkgs, ... }:

let

  cfg = config.services.immich;
  inherit (lib) mkIf mkBefore;
  inherit (import ./shared.nix { inherit config; }) 
    version uid gid environment environmentFiles extraOptions serviceConfig;

in {

  config = mkIf cfg.enable {

    # Web front-end
    virtualisation.oci-containers.containers.immich-web = {
      image = "ghcr.io/immich-app/immich-web:v${version}";
      entrypoint = "/bin/sh";
      cmd = [ "./entrypoint.sh" ];
      inherit environment environmentFiles extraOptions;
    };
      
    systemd.services.docker-immich-web = {
      preStart = mkBefore ''
        #
        # Ensure docker network exists
        ${pkgs.docker}/bin/docker network create immich 2>/dev/null || true
        #
        # Ensure data directory exists with expected ownership
        mkdir -p ${cfg.dataDir}/geocoding
        chown -R ${uid}:${gid} ${cfg.dataDir}
        #
        # Ensure database user has expected password
        ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql postgres \
          -c "alter user immich with password '$DB_PASSWORD'"
      '';
      inherit serviceConfig;
    };

  };

}
