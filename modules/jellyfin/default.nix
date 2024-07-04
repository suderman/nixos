# services.jellyfin.enable = true;
{ config, lib, pkgs, this, ... }:

let

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
      user = "jellyfin";
      group = "media";
      openFirewall = true;
    };

    users.groups.media.members = [ config.services.jellyfin.user ];

    services.traefik = { 
      enable = true;
      routers = let router = {
        hostName = mkHostName cfg.name;
        url = "http://127.0.0.1:${toString cfg.port}";
        public = false;
      }; in {
        jellyfin-websecure = router;
        jellyfin-web = router // { tls = false; };
      };
    };

  };

}
