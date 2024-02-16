# modules.tailscale.enable = true;
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
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.tailscale;
  inherit (config.age) secrets;
  inherit (lib) mkAfter mkIf mkOption types;
  inherit (lib.options) mkEnableOption;

in {

  options.modules.tailscale = {
    enable = lib.options.mkEnableOption "tailscale"; 
    deleteRoute = mkOption { type = types.str; default = ""; };
  };

  config = mkIf cfg.enable {

    services.tailscale.enable = true;

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
        sleep 30
        if [[ ! -z "$(ip route show table 52 | grep ${route})" ]]; then
          ip route del ${route} dev tailscale0 table 52
        fi
      '';
    };

    # systemd.services."tailscale-web" = {
    #   serviceConfig.Type = "simple";
    #   wantedBy = [ "multi-user.target" ];
    #   after = [ "network.target" ];
    #   path = with pkgs; [ tailscale ];
    #   script = ''tailscale web --prefix https://${hostName}'';
    # };

    # # Enable reverse proxy
    # modules.traefik = {
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

    systemd.extraConfig = ''
      DefaultTimeoutStopSec=30s
    '';

    # # Tailscale IP in Cloudflare DNS
    # systemd.services."tailscale-dns" = {
    #   serviceConfig = {
    #     Type = "oneshot";
    #     EnvironmentFile = secrets.cloudflare-env.path;
    #   };
    #   environment = with config.networking; {
    #     DOMAIN = domain;
    #   };
    #   path = with pkgs; [ coreutils curl gawk jq tailscale ];
    #   script = builtins.readFile ./tailscale-dns.sh;
    # };
    #
    # # Run this script every day
    # systemd.timers."tailscale-dns" = {
    #   wantedBy = [ "timers.target" ];
    #   partOf = [ "tailscale-dns.service" ];
    #   timerConfig = {
    #     OnCalendar = "daily";
    #     Unit = "tailscale-dns.service";
    #   };
    # };

    # # If tailscale is enabled, provide convenient hostnames to each IP address
    # # These records also exist in Cloudflare DNS, so it's a duplicated effort here.
    # services.dnsmasq.enable = mkIf cfg.enable true;
    # services.dnsmasq.extraConfig = with config.networking; mkIf cfg.enable ''
    #   address=/.local.${domain}/127.0.0.1
    #   address=/.cog.${domain}/100.67.140.102
    #   address=/.lux.${domain}/100.103.189.54
    #   address=/.graphene.${domain}/100.101.42.9
    # '';

  };

}
