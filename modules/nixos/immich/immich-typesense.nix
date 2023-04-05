{ config, lib, pkgs, ... }:

let

  cfg = config.services.immich;
  inherit (import ./shared.nix { inherit config; }) 
    version uid gid environment environmentFiles extraOptions serviceConfig;

in {

  config = lib.mkIf cfg.enable {

    # Typesense search engine
    virtualisation.oci-containers.containers.immich-typesense = {
      image = "typesense/typesense:0.24.0";
      volumes = [ "tsdata:/data" ];
      inherit environment environmentFiles extraOptions;
    };

    systemd.services.docker-immich-typesense = {
      after = [ "docker-immich-redis.service" ];
    };

  };

}
