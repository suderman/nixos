{ inputs, config, pkgs, lib, ... }:
  
let 
  name = "whoami";
  sub = "whoami";
  cfg = config.services.whoami;
  inherit (config) secrets;
  inherit (lib) mkIf;

in {
  options = {
    services."${name}".enable = lib.options.mkEnableOption "${name}"; 
  };

  # services.whoami.enable = true;
  config = with config.networking; mkIf cfg.enable {

    virtualisation.oci-containers.containers."${name}" = {
      image = "traefik/whoami";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.${name}.rule=Host(`${sub}.${hostName}.${domain}`) || Host(`${sub}.local.${domain}`)"
        "--label=traefik.http.routers.${name}.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.${name}.middlewares=basicauth@file"
      ];
      environmentFiles = mkIf secrets.enable [ config.age.secrets.self-env.path ];
      environment = {
        JONNY = "super awesome";
        MYPORT = "$SELF_SMTP_PORT";
      };
    };

    # agenix
    age.secrets = with secrets; mkIf secrets.enable {
      self-env.file = self-env;
    };

  }; 


}
