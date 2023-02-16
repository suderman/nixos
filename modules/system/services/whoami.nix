{ inputs, config, pkgs, lib, ... }:
  
let 
  cfg = config.services.whoami;
  inherit (lib) mkIf;

  # agenix secrets combined with age files paths
  age = config.age // { 
    files = config.secrets.files; 
    enable = config.secrets.enable; 
  };

in {
  options = {
    services.whoami.enable = lib.options.mkEnableOption "whoami"; 
  };

  # services.whoami.enable = true;
  config = with config.networking; mkIf cfg.enable {

    # agenix
    age.secrets = mkIf age.enable {
      self-env.file = age.files.self-env;
    };

    # service
    virtualisation.oci-containers.containers."whoami" = {
      image = "traefik/whoami";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.whoami.rule=Host(`whoami.${hostName}.${domain}`) || Host(`whoami.local.${domain}`)"
        "--label=traefik.http.routers.whoami.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.whoami.middlewares=local@file"
      ];
      environmentFiles = mkIf age.enable [ age.secrets.self-env.path ];
      environment = {
        JONNY = "super awesome";
        MYPORT = "$SELF_SMTP_PORT";
      };
    };

  }; 


}
