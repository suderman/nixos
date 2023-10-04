# modules.whoami.enable = true;
{ inputs, config, pkgs, lib, ... }:
  
let 
  cfg = config.modules.whoami;
  secrets = config.age.secrets;
  inherit (lib) mkIf;

in {

  options.modules.whoami = {
    enable = lib.options.mkEnableOption "whoami"; 
  };

  config = mkIf cfg.enable {

    # service
    virtualisation.oci-containers.containers."whoami" = with config.networking; {
      image = "traefik/whoami";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.whoami.rule=Host(`whoami.${hostName}.${domain}`) || Host(`whoami.local.${domain}`)"
        "--label=traefik.http.routers.whoami.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.whoami.middlewares=local@file"
      ];
      environmentFiles = [ secrets.traefik-env.path ];
      environment = {
        FOO = "BAR";
      };
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

  }; 

}
