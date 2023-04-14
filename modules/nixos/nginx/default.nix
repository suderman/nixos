# modules.nginx.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.nginx;
  inherit (lib) mkIf;

in {

  options.modules.nginx = {
    enable = lib.options.mkEnableOption "nginx"; 
  };

  config = mkIf cfg.enable {

    # 80 and 443 are already taken by traefik
    services.nginx = {
      enable = true;
      defaultHTTPListenPort = 9080;
      defaultSSLListenPort = 9443;
    };

  };

}
