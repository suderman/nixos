{ config, lib, pkgs, ... }:

let
  cfg = config.services.tailscale;
  inherit (lib) mkIf;

  # agenix secrets combined with age files paths
  age = config.age // { 
    files = config.secrets.files; 
    enable = config.secrets.enable; 
  };

in {

  # services.tailscale.enable = true;
  networking.firewall = mkIf cfg.enable {
    checkReversePath = "loose";
    allowedUDPPorts = [ 41641 ]; # Facilitate firewall punching
  };

  # If tailscale is enabled, provide convenient hostnames to each IP address
  # These records also exist in Cloudflare DNS, so it's a duplicated effort here.
  services.dnsmasq.enable = mkIf cfg.enable true;
  services.dnsmasq.extraConfig = with config.networking; mkIf cfg.enable ''
    address=/.local.${domain}/127.0.0.1
    address=/.cog.${domain}/100.67.140.102
    address=/.lux.${domain}/100.103.189.54
    address=/.graphene.${domain}/100.101.42.9
  '';

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  age.secrets = mkIf age.enable {
    tailscale-cloudflare = {
      file = age.files.tailscale-cloudflare;
      owner = "me";
      group = "users";
    };
  };

}
