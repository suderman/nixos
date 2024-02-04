# modules.sonarr.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.sonarr;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;

in {

  options.modules.sonarr = {
    enable = options.mkEnableOption "sonarr"; 
    name = mkOption {
      type = types.str; 
      default = "sonarr";
    };
    port = mkOption {
      type = types.port;
      default = 8989; 
    };
    dataDir= mkOption {
      type = types.str; 
      default = "/var/lib/sonarr"; 
    };
  };

  config = mkIf cfg.enable {

    services.sonarr = {
      enable = true;
      user = "sonarr";
      group = "media";
      package = pkgs.sonarr;
      dataDir = cfg.dataDir;
    };

    users.groups.media.members = [ config.services.sonarr.user ];

    modules.traefik = {
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };

  };

}
