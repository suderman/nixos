{ config, lib, pkgs, ... }:

let

  cfg = config.services.immich;
  inherit (import ./shared.nix { inherit config; }) 
    version uid gid environment environmentFiles extraOptions serviceConfig;

in {

  config = lib.mkIf cfg.enable {

    # Redis cache
    virtualisation.oci-containers.containers.immich-redis = {
      image = "redis:6.2";
      inherit environment environmentFiles extraOptions;
    };

    systemd.services.docker-immich-redis = {
      after = [ "docker-immich-web.service" ];
    };

  };

}
