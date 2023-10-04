# modules.lunasea.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.lunasea;
  inherit (lib) mkIf mkOption options types strings;
  inherit (builtins) toString;

in {

  options.modules.lunasea = {

    enable = options.mkEnableOption "lunasea"; 

    hostName = mkOption {
      type = types.str;
      default = "lunasea.${config.networking.fqdn}";
      description = "FQDN for the LunaSea instance";
    };

  };

  config = mkIf cfg.enable {

    # Enable reverse proxy
    modules.traefik.enable = true;

    virtualisation.oci-containers.containers.lunasea = {
      image = "ghcr.io/jagandeepbrar/lunasea:stable";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.lunasea.rule=Host(`${cfg.hostName}`)"
        "--label=traefik.http.routers.lunasea.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.lunasea.middlewares=local@file"
      ];
    };

  };

}
