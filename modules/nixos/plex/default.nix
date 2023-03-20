# services.plex.enable = true;
{ config, lib, pkgs, ... }:


let
  cfg = config.services.plex;
  port = "32400"; 

in {

  config = lib.mkIf cfg.enable {

    services.plex.user = "plex";
    services.plex.group = "plex";
    services.plex.extraPlugins = [];
    services.plex.extraScanners = [];
    services.plex.openFirewall = true;
    services.plex.package = pkgs.plex;

    services.traefik.dynamicConfigOptions.http = with config.networking; {
      routers.plex = {
        entrypoints = "websecure";
        rule = "Host(`plex.${hostName}.${domain}`) || Host(`plex.local.${domain}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "plex";
      };
      services.plex.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];

    };

    # https://www.plex.tv/claim/
    # sudo plex-claim-server claim-xxxxxxxxxxxxxxxxxxxx
    environment.systemPackages = [
      ( pkgs.writeShellScriptBin "plex-claim-server" (builtins.readFile ./plex-claim-server.sh) )
    ];

  };

}
