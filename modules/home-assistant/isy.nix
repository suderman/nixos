{ config, lib, this, ... }:

let

  cfg = config.modules.home-assistant;
  inherit (lib) mkIf;

in {

  config = mkIf (cfg.enable && cfg.isy != "") {

    modules.traefik = { 
      enable = true;
      routers.${cfg.isyName} = "http://${cfg.isy}:80";
      http = {
        middlewares.isy.headers.customRequestHeaders.authorization = "Basic {{ env `ISY_BASIC_AUTH` }}";
        routers.${cfg.isyName}.middlewares = [ "isy" ];
      };
    };

  };

}
