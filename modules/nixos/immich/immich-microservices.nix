{ config, lib, pkgs, ... }:

let

  cfg = config.services.immich;
  inherit (import ./shared.nix { inherit config; }) 
    version uid gid environment environmentFiles extraOptions serviceConfig;

in {

  config = lib.mkIf cfg.enable {

    # Microservices
    # https://github.com/immich-app/immich/issues/776#issuecomment-1271459885
    virtualisation.oci-containers.containers.immich-microservices = {
      image = "ghcr.io/immich-app/immich-server:v${version}";
      entrypoint = "/bin/sh";
      cmd = [ "./start-microservices.sh" ];
      user = "${uid}:${gid}"; 
      volumes = [ 
        "${cfg.dataDir}:/usr/src/app/upload" 
        "${cfg.dataDir}/geocoding:/usr/src/app/geocoding"
      ];
      inherit environment environmentFiles extraOptions;
    };

    systemd.services.docker-immich-microservices = {
      requires = [ "docker-immich-typesense.service" "docker-immich-redis.service" "postgresql.service" ];
      after = [ "docker-immich-typesense.service" ];
      inherit serviceConfig;
    };

  };

}
