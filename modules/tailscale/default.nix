# services.tailscale.enable = true;
#
# I want all my tailscale machines to have DNS records in Cloudflare
#
# If I have a machine named foo with IP address 100.65.1.1, and another
# named bar with IP address 100.65.1.2, this will create four records: 
#     foo.mydomain.org -> A     -> 100.65.1.1
#     bar.mydomain.org -> A     -> 100.65.1.2
#   *.foo.mydomain.org -> CNAME -> foo.mydomain.org
#   *.bar.mydomain.org -> CNAME -> bar.mydomain.org
# 
# This is true for all my tailscale machines, and two localhost records: 
#     local.mydomain.org -> A     -> 127.0.0.1
#   *.local.mydomain.org -> CNAME -> local.mydomain.org
#
{ config, lib, pkgs, ... }:

let

  cfg = config.services.tailscale;
  inherit (config.age) secrets;
  inherit (lib) mkAfter mkIf mkOption types;

in {

  options.services.tailscale = {
    deleteRoute = mkOption { type = types.str; default = ""; };
  };

  config = mkIf cfg.enable {

    networking.firewall = {
      checkReversePath = "loose";  # https://github.com/tailscale/tailscale/issues/4432
      allowedUDPPorts = [ 41641 ]; # Facilitate firewall punching
    };

    systemd.services."tailscale-delete-route" = {
      serviceConfig.Type = "simple";
      wantedBy = [ "multi-user.target" ];
      after = [ "tailscaled.service" ];
      path = with pkgs; [ gnugrep iproute2 ];
      script = let route = if cfg.deleteRoute == "" then "SKIP" else cfg.deleteRoute; in ''
        while [[ -z $(ip route show table all | grep "table 52") ]]; do
          echo "Table 52 is empty. Waiting for 10 seconds..."
          sleep 10
        done
        if [[ ! -z "$(ip route show table 52 | grep ${route})" ]]; then
          echo "Delete route ${route} from table 52"
          ip route del ${route} dev tailscale0 table 52
        fi
      '';
    };

    systemd.extraConfig = ''
      DefaultTimeoutStopSec=30s
    '';

    # systemd.services."tailscale-web" = {
    #   serviceConfig.Type = "simple";
    #   wantedBy = [ "multi-user.target" ];
    #   after = [ "network.target" ];
    #   path = with pkgs; [ tailscale ];
    #   script = ''tailscale web --prefix https://${hostName}'';
    # };

    # # Enable reverse proxy
    # services.traefik = {
    #   enable = true;
    #   certificates = [ hostName ];
    # };
    #
    # services.traefik.dynamicConfigOptions.http = {
    #   routers.tailscale = {
    #     rule = "Host(`${hostName}`)";
    #     middlewares = "local@file"; tls = {};
    #     service = "tailscale";
    #   };
    #   services.tailscale.loadBalancer.servers = [{ url = "http://100.100.100.100"; }];
    # };

  };

}
