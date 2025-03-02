{ config, lib, this, ... }: let

  cfg = config.services.traefik;
  inherit (builtins) dirOf toString;
  inherit (lib) mkIf mkOption types;

in {

  options.services.traefik = {
   caPort = mkOption {
      type = types.port;
      default = 0; 
    };
  };

  config = mkIf (cfg.caPort > 0) {

    # Use nginx to serve the certificate
    services.nginx.enable = true;

    # Configure virtual host on specified port
    services.nginx.virtualHosts.ca = {
      listen = [{ addr = "0.0.0.0"; port = cfg.caPort; }];
      locations."/" = let index = "ca.crt"; in {
        inherit index;
        root = dirOf this.ca;
        extraConfig = ''
          add_header Content-disposition "attachment; filename=${index}";
        '';
      };
    };

    # Open up the firewall for this port
    networking.firewall.allowedTCPPorts = [ cfg.caPort ];

    # Also serve the ca.crt via traefik
    services.traefik.proxy.ca = "http://127.0.0.1:${toString cfg.caPort}";

  };

}
