# modules.bluebubbles.enable = true;
{ inputs, config, pkgs, lib, ... }:
  
let 

  cfg = config.modules.bluebubbles;
  inherit (lib) mkIf mkOption mkBefore types;
  inherit (builtins) toString;

in {

  options.modules.bluebubbles = {

    enable = lib.options.mkEnableOption "bluebubbles"; 

    hostName = mkOption {
      type = types.str;
      default = "bluebubbles.${config.networking.fqdn}";
      description = "FQDN for the bluebubbles server";
    };

    ip = mkOption {
      type = types.str;
      default = "192.168.2.8";
      description = "IP address for the bluebubbles server";
    };

    port = mkOption {
      description = "Port for bluebubbles server";
      default = 1234;
      type = types.port;
    };

  };

  config = mkIf cfg.enable {

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Reverse proxy
    services.traefik.dynamicConfigOptions.http = {
      routers.bluebubbles = {
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        service = "bluebubbles";
      };
      services.bluebubbles.loadBalancer.servers = [{ url = "http://${cfg.ip}:${toString cfg.port}"; }];
    };

  }; 

}
