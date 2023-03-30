# services.nginx.enable = true;
{ config, lib, pkgs, ... }:

let
  cfg = config.services.nginx;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # 80 and 443 are already taken by traefik
    services.nginx = {
      defaultHTTPListenPort = 9080;
      defaultSSLListenPort = 9443;
    };

  };

}
