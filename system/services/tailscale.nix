{ config, lib, pkgs, ... }:

let
  cfg = config.services.tailscale;

in {

  # services.tailscale.enable = true;
  networking.firewall = lib.mkIf cfg.enable {
    checkReversePath = "loose";
    allowedUDPPorts = [ 41641 ]; # Facilitate firewall punching
  };

  # If tailscale is enabled, provide convenient hostnames to each IP address
  # These records also exist in Cloudflare DNS, so it's a duplicated effort here.
  services.dnsmasq.enable = lib.mkIf cfg.enable true;
  services.dnsmasq.extraConfig = with config.networking; lib.mkIf cfg.enable ''
    address=/.local.${domain}/127.0.0.1
    address=/.cog.${domain}/100.67.140.102
    address=/.lux.${domain}/100.103.189.54
    address=/.graphene.${domain}/100.101.42.9
  '';

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  age.secrets = with config.secrets; {
    tailscale-cloudflare = {
      file = tailscale-cloudflare;
      owner = "me";
      group = "users";
    };
  };

  # environment.etc."tscf.env".source = config.age.secrets.tailscale-cloudflare.path;

}
