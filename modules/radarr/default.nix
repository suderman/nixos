# modules.radarr.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.radarr;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;

in {

  options.modules.radarr = {
    enable = options.mkEnableOption "radarr"; 
    name = mkOption {
      type = types.str; 
      default = "radarr";
    };
    port = mkOption {
      type = types.port;
      default = 7878; 
    };
    dataDir = mkOption {
      type = types.str; 
      default = "/var/lib/radarr"; 
    };
  };

  config = mkIf cfg.enable {

    services.radarr = {
      enable = true;
      user = "radarr";
      group = "media";
      package = pkgs.radarr;
      dataDir = cfg.dataDir;
    };

    users.groups.media.members = [ config.services.radarr.user ];

    modules.traefik = { 
      enable = true;
      routers."${cfg.name}" = "http://127.0.0.1:${toString cfg.port}";
    };

  };

}
