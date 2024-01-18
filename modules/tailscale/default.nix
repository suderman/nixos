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
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.tailscale;
  inherit (config.age) secrets;
  inherit (lib) mkIf;

in {

  options.modules.tailscale = {
    enable = lib.options.mkEnableOption "tailscale"; 
  };

  config = mkIf cfg.enable {

    services.tailscale.enable = true;

    networking.firewall = {
      checkReversePath = "loose";  # https://github.com/tailscale/tailscale/issues/4432
      allowedUDPPorts = [ 41641 ]; # Facilitate firewall punching
    };

    systemd.services."tailscale-dns" = {
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = secrets.cloudflare-env.path;
      };
      environment = with config.networking; {
        DOMAIN = domain;
      };
      path = with pkgs; [ coreutils curl gawk jq tailscale ];
      script = builtins.readFile ./tailscale-dns.sh;
    };

    # Run this script every day
    systemd.timers."tailscale-dns" = {
      wantedBy = [ "timers.target" ];
      partOf = [ "tailscale-dns.service" ];
      timerConfig = {
        OnCalendar = "daily";
        Unit = "tailscale-dns.service";
      };
    };

    systemd.extraConfig = ''
      DefaultTimeoutStopSec=30s
    '';

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
