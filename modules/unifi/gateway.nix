{ config, lib, pkgs, ... }: let

  cfg = config.services.unifi;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    services.traefik = { 
      enable = true;
      proxy.${cfg.gatewayName} = "https://${cfg.gateway}:443";
    };

  };

}
