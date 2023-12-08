# modules.plex.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.plex;
  port = "32400"; 
  inherit (lib) mkIf mkOption types;
  inherit (this.lib) extraGroups;

in {

  options.modules.plex = {
    enable = lib.options.mkEnableOption "plex"; 
    hostName = mkOption {
      type = types.str;
      default = "plex.${config.networking.fqdn}";
      description = "FQDN for the Plex instance";
    };
  };

  config = mkIf cfg.enable {

    services.plex = {
      enable = true;
      user = "plex"; # default
      group = "plex"; # default
      extraPlugins = [];
      extraScanners = [];
      openFirewall = true;
      package = pkgs.plex;
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Traefik configuration
    services.traefik.dynamicConfigOptions.http = {
      routers.plex = {
        entrypoints = "websecure";
        rule = "Host(`${cfg.hostName}`)";
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

    # Add admins to the plex group
    users.users = extraGroups this.admins [ "plex" ];

  };

}
