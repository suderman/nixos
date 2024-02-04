{ config, lib, pkgs, ... }:

let

  cfg = config.modules.unifi;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    modules.traefik = { 
      enable = true;
      routers.${cfg.gatewayName} = "https://${cfg.gateway}:443";
    };

  };

}
