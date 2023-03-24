# services.plex.enable = true;
{ config, lib, pkgs, user, ... }:

let

  cfg = config.services.plex;
  port = "32400"; 
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    services.plex.user = "plex"; # default
    services.plex.group = "plex"; # default
    services.plex.extraPlugins = [];
    services.plex.extraScanners = [];
    services.plex.openFirewall = true;
    services.plex.package = pkgs.plex;

    services.traefik.dynamicConfigOptions.http = {
      routers.plex = with config.networking; {
        entrypoints = "websecure";
        rule = "Host(`plex.${hostName}.${domain}`)";
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

    # Add user to the plex group
    users.users."${user}".extraGroups = [ "plex" ]; 

  };

}
