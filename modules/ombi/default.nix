# modules.ombi.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.ombi;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;

in {

  options.modules.ombi = {
    enable = options.mkEnableOption "ombi"; 
    name = mkOption {
      type = types.str; 
      default = "ombi";
    };
    port = mkOption {
      type = types.port;
      default = 5099; 
    };
  };

  config = mkIf cfg.enable {

    services.ombi = {
      enable = true;
      user = "ombi";
      group = "media";
      port = cfg.port;
    };

    users.groups.media.members = [ config.services.ombi.user ];

    modules.traefik = {
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };

  };

}
