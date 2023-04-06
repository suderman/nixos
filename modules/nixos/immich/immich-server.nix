{ config, lib, pkgs, ... }:

let

  cfg = config.services.immich;
  inherit (lib) mkIf;
  inherit (import ./shared.nix { inherit config; }) 
    version uid gid environment environmentFiles extraOptions serviceConfig;

in {

  config = mkIf cfg.enable {

    # Server back-end
    virtualisation.oci-containers.containers.immich-server = {
      image = "ghcr.io/immich-app/immich-server:v${version}";
      entrypoint = "/bin/sh";
      cmd = [ "./start-server.sh" ];
      user = "${uid}:${gid}";
      volumes = [ "${cfg.dataDir}:/usr/src/app/upload" ];
      inherit environment environmentFiles extraOptions;
    };

    systemd.services.docker-immich-server = {
      requires = [ "docker-immich-typesense.service" "docker-immich-redis.service" "postgresql.service" ];
      after = [ "docker-immich-typesense.service" ];
      inherit serviceConfig;
    };

  };

}
