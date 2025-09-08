# services.tailscale.enable = true;
{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.services.tailscale;
  inherit (lib) mkIf mkOption types;
in {
  options.services.tailscale = {
    deleteRoute = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      # tailscale-1.82.5 (stable) fails to build (and isn't in binary cache)
      package = perSystem.nixpkgs-unstable.tailscale;
      extraSetFlags = [
        "--accept-routes" # accept routes from LAN router
        "--accept-dns=false" # Use local Blocky for DNS, not Tailscale
      ];
      openFirewall = true;
    };

    # https://github.com/tailscale/tailscale/issues/4432
    networking.firewall.checkReversePath = "loose";

    systemd.services."tailscale-delete-route" = {
      serviceConfig.Type = "simple";
      wantedBy = ["multi-user.target"];
      after = ["tailscaled.service"];
      path = with pkgs; [gnugrep iproute2];
      script = let
        route =
          if cfg.deleteRoute == ""
          then "SKIP"
          else cfg.deleteRoute;
      in ''
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

    # Persist data between reboots
    persist.storage.directories = ["/var/lib/tailscale"];
  };
}
