# modules.netdata.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.netdata;
  port = "19999";
  inherit (config.users) user;
  inherit (lib) mkIf mkOption types;

in {

  options.modules.netdata = {
    enable = lib.options.mkEnableOption "netdata"; 
    hostName = mkOption {
      type = types.str;
      default = "netdata.${config.networking.fqdn}";
      description = "FQDN for the Netdata instance";
    };
  };

  config = mkIf cfg.enable {

    services.netdata = {
      enable = true;
      config = {
        global = {
          # uncomment to reduce memory to 32 MB
          #"page cache size" = 32;

          # update interval
          "update every" = 15;
        };
        ml = {
          # enable machine learning
          "enabled" = "yes";
        };      
      };
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Traefik configuration
    services.traefik.dynamicConfigOptions.http = {
      routers.netdata = {
        entrypoints = "websecure";
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "netdata";
      };
      services.netdata.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];
    };

    # TODO: claim script when using cloud. Check Plex how this could be done

    # Add user to the netdata group
    users.users."${user}".extraGroups = [ "netdata" ]; 

  };

}
