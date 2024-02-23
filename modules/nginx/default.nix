# modules.nginx.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.nginx;
  inherit (config.services.prometheus) exporters;
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
    services = let
      httpPort = 9080;
      httpsPort = 9443;
    in {

      nginx = {
        enable = true;
        statusPage = true;
        defaultHTTPListenPort = httpPort;
        defaultSSLListenPort = httpsPort;
      };

      prometheus = {

        exporters = {
          nginx = { 
            enable = true; 
            scrapeUri = "http://127.0.0.1:${toString httpPort}/nginx_status";
          };
          nginxlog.enable = true; 
        };

        scrapeConfigs = [{ 
          job_name = "nginx"; static_configs = [ 
            { targets = [ "127.0.0.1:${toString exporters.nginx.port}" ]; } 
          ]; 
        } {
          job_name = "nginxlog"; static_configs = [ 
            { targets = [ "127.0.0.1:${toString exporters.nginxlog.port}" ]; } 
          ]; 
        }];

      };

    };

  };

}
