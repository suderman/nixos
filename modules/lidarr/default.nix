# modules.lidarr.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.lidarr;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;

in {

  options.modules.lidarr = {
    enable = options.mkEnableOption "lidarr"; 
    name = mkOption {
      type = types.str; 
      default = "lidarr";
    };
    port = mkOption {
      type = types.port;
      default = 8686; 
    };
    dataDir = mkOption {
      type = types.str; 
      default = "/var/lib/lidarr"; 
    };
  };

  config = mkIf cfg.enable {

    services.lidarr = {
      enable = true;
      user = "lidarr";
      group = "media";
      package = pkgs.lidarr;
      dataDir = cfg.dataDir;
    };

    users.groups.media.members = [ config.services.lidarr.user ];

    modules.traefik = {
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };

  };

}
