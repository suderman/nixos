# -- modified module --
# services.jellyfin.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.jellyfin;
  inherit (lib) mkIf mkOption types;
  inherit (config.services.traefik.lib) mkHostName;
in {
  options.services.jellyfin = {
    name = mkOption {
      type = types.str;
      default = "jellyfin";
    };
    port = mkOption {
      type = types.port;
      default = 8096;
    };
  };

  config = mkIf cfg.enable {
    services.jellyfin = {
      # Jellyfin 12 migrates the database on first start; back up /var/lib/jellyfin first
      package = pkgs.unstable.jellyfin;
      user = "jellyfin";
      group = "media";
      openFirewall = true;
    };

    users.groups.media.members = [config.services.jellyfin.user];

    services.traefik = {
      enable = true;
      proxy = let
        route = {
          hostName = mkHostName cfg.name;
          url = "http://127.0.0.1:${toString cfg.port}";
          public = false;
        };
      in {
        jellyfin-websecure = route;
        jellyfin-web = route // {tls = false;};
      };
    };

    # Persist data between reboots
    persist.storage.directories = ["/var/lib/jellyfin"];
  };
}
