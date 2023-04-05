{ config, lib, pkgs, ... }:

let

  cfg = config.services.immich;
  inherit (import ./shared.nix { inherit config; }) 
    version uid gid environment environmentFiles extraOptions serviceConfig;

in {

  config = lib.mkIf cfg.enable {

    # Reverse proxy server
    virtualisation.oci-containers.containers.immich-proxy = {
      image = "ghcr.io/immich-app/immich-proxy:v${version}";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.immich.rule=Host(`${cfg.host}`)"
        "--label=traefik.http.routers.immich.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.immich.middlewares=local@file"
      ] ++ extraOptions;
      inherit environment environmentFiles;
    };

    systemd.services.docker-immich-proxy = {
      requires = [ "docker-immich-server.service" ];
      after = [ "docker-immich-server.service" ];
    };

  };

}
