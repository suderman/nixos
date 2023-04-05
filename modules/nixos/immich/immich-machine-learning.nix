{ config, lib, pkgs, ... }:

let

  cfg = config.services.immich;
  inherit (import ./shared.nix { inherit config; }) 
    version uid gid environment environmentFiles extraOptions serviceConfig;

in {

  config = lib.mkIf cfg.enable {

    # Machine learning
    virtualisation.oci-containers.containers.immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:v${version}";
      volumes = [ 
        "${cfg.dataDir}:/usr/src/app/upload" 
        "model-cache:/cache"
      ];
      inherit environment environmentFiles extraOptions;
    };

    systemd.services.docker-immich-machine-learning = {
      requires = [ "docker-immich-typesense.service" "docker-immich-redis.service" "postgresql.service" ];
      after = [ "docker-immich-typesense.service" ];
      inherit serviceConfig;
    };

  };

}
