# modules.nginx.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.nginx;
  inherit (lib) mkIf mkOption types;

in {

  options.modules.nginx = {

    enable = lib.options.mkEnableOption "nginx"; 

    # Enable self-signed certificate https:
    # config.services.nginx.virtualHosts."foo" = { ... } // config.modules.nginx.ssl
    ssl = mkOption { 
      type = types.attrs; 
      default = {
        addSSL = true;
        # TODO: generate my own certificate and not use acme test cert for convenience
        sslCertificate = "${pkgs.path}/nixos/tests/common/acme/server/acme.test.cert.pem";
        sslCertificateKey = "${pkgs.path}/nixos/tests/common/acme/server/acme.test.key.pem";
      };
    };

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
