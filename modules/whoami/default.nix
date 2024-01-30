# modules.whoami.enable = true;
{ inputs, config, lib, pkgs, this, ... }:
  
let 
  cfg = config.modules.whoami;
  inherit (config.age) secrets;
  inherit (lib) mkIf;

  domain = "whoami.${this.host}";

in {

  options.modules.whoami = {
    enable = lib.options.mkEnableOption "whoami"; 
  };

  config = mkIf cfg.enable {

    # service
    virtualisation.oci-containers.containers."whoami" = {
      image = "traefik/whoami";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.whoami.rule=Host(`${domain}`)"
        "--label=traefik.http.routers.whoami.tls=true"
        "--label=traefik.http.routers.whoami.middlewares=local@file"
      ];
      environmentFiles = [ secrets.traefik-env.path ];
      environment = {
        FOO = "BAR";
      };
    };

    # Enable reverse proxy
    modules.traefik.enable = true;
    modules.traefik.certificates = [ domain ];

  }; 

}
