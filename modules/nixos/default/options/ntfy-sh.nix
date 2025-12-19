# services.ntfy-sh.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.services.ntfy-sh;
  inherit (lib) mkIf mkOption types;
in {
  options.services.ntfy-sh = {
    name = mkOption {
      type = types.str;
      default = "ntfy";
    };
  };

  config = mkIf cfg.enable {
    # Open firewall
    networking.firewall.allowedTCPPorts = [2586];

    # Use reverse proxy
    services.ntfy-sh.settings = {
      base-url = "https://${cfg.name}.${config.networking.hostName}";
      behind-proxy = true;
    };

    # Create reverse proxy
    services.traefik.proxy.${cfg.name} = "http://127.0.0.1:2586";
  };
}
