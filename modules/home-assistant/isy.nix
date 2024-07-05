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

    services.traefik = { 
      enable = true;
      proxy.${cfg.isyName} = "http://${cfg.isy}:80";
      dynamicConfigOptions.http.middlewares.${cfg.isyName}.headers = {
        customRequestHeaders.authorization = "Basic {{ env `ISY_BASIC_AUTH` }}";
      };
    };

  };

}
