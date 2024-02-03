# modules.bluebubbles.enable = true;
{ config, lib, this, ... }:
  
let 

  cfg = config.modules.bluebubbles;
  inherit (lib) mkIf mkOption mkBefore types;
  inherit (builtins) toString;

in {

  options.modules.bluebubbles = {

    enable = lib.options.mkEnableOption "bluebubbles"; 

    hostName = mkOption {
      type = types.str;
      default = "bluebubbles.${this.hostName}";
    };

    ip = mkOption {
      type = types.str;
      default = "10.2.0.3";
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
    modules.traefik.certificates = [ cfg.hostName ];

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
