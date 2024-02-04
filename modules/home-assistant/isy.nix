{ config, lib, this, ... }:

let

  cfg = config.modules.home-assistant;
  inherit (lib) mkIf;

in {

  config = mkIf (cfg.enable && cfg.isy != "") {

    modules.traefik = { 
      enable = true;
      routers.isy = "http://${cfg.isy}:80";
      http = {
        middlewares.isy.headers.customRequestHeaders.authorization = "Basic {{ env `ISY_BASIC_AUTH` }}";
        routers.isy.middlewares = [ "isy" ];
      };
    };

  };

}
