# services.tailscale.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.tailscale;
  inherit (lib) mkIf mkOption types;
in {
  options.services.tailscale = {
    preferLocalRoute = mkOption {
      type = types.str;
      default = "";
      description = "Subnet that should use the main routing table before Tailscale routes.";
    };
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      # tailscale-1.82.5 (stable) fails to build (and isn't in binary cache)
      package = pkgs.unstable.tailscale;
      extraSetFlags = [
        "--accept-routes" # accept routes from LAN router
        "--accept-dns=false" # Use local Blocky for DNS, not Tailscale
      ];
      openFirewall = true;
    };

    # https://github.com/tailscale/tailscale/issues/4432
    networking.firewall.checkReversePath = "loose";

    # Keep a directly connected LAN preferred when another Tailscale subnet
    # router advertises the same prefix for high availability.
    systemd.services.tailscale-prefer-local-route = mkIf (cfg.preferLocalRoute != "") {
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      wantedBy = ["multi-user.target"];
      before = ["tailscaled.service"];
      path = [pkgs.iproute2];
      script = ''
        ip rule del to ${cfg.preferLocalRoute} priority 2500 lookup main 2>/dev/null || true
        ip rule add to ${cfg.preferLocalRoute} priority 2500 lookup main
      '';
      preStop = ''
        ip rule del to ${cfg.preferLocalRoute} priority 2500 lookup main 2>/dev/null || true
      '';
    };
    systemd.settings.Manager.DefaultTimeoutStopSec = "30s";

    # Persist data between reboots
    persist.storage.directories = ["/var/lib/tailscale"];
  };
}
