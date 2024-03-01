{ config, lib, this, ... }:

let

  cfg = config.modules.home-assistant;
  inherit (lib) mkIf;
  inherit (config.age) secrets;

in {

  config = mkIf (cfg.enable && cfg.isy != "") {

    # Encoded ISY authentication header
    # > echo -n $ISY_USERNAME:$ISY_PASSWORD | base64
    # ---------------------------------------------------------------------------
    # ISY_BASIC_AUTH=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
    # ---------------------------------------------------------------------------
    systemd.services.traefik.serviceConfig = {
      EnvironmentFile = [ secrets.isy-env.path ];
    };

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
