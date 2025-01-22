# -- custom module --
# services.bluebubbles.enable = true;
{ config, lib, this, ... }:
  
let 

  cfg = config.services.bluebubbles;
  inherit (lib) mkIf mkOption mkBefore types;
  inherit (builtins) toString;

in {

  options.services.bluebubbles = {

    enable = lib.options.mkEnableOption "bluebubbles"; 

    name = mkOption {
      type = types.str;
      default = "bluebubbles";
    };

    ip = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "IP address for the bluebubbles server";
    };

    port = mkOption {
      description = "Port for bluebubbles server";
      default = 1234;
      type = types.port;
    };

  };

  config = mkIf cfg.enable {

    services.traefik = {
      enable = true;
      proxy.${cfg.name} = "http://${cfg.ip}:${toString cfg.port}";
    };

  }; 

}
