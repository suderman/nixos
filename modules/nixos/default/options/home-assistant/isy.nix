{
  config,
  lib,
  ...
}: let
  cfg = config.services.home-assistant;
  inherit (lib) mkIf;
in {
  config = mkIf (cfg.enable && cfg.isy != "") {
    # Encoded ISY authentication header
    # > echo -n $ISY_USERNAME:$ISY_PASSWORD | base64
    # ---------------------------------------------------------------------------
    # ISY_BASIC_AUTH=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    # ---------------------------------------------------------------------------
    age.secrets.isy.rekeyFile = ./isy.age;
    systemd.services.traefik.serviceConfig = {
      EnvironmentFile = [config.age.secrets.isy.path];
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
