{ inputs, config, pkgs, lib, ... }:
  
let 
  name = "whoami";
  sub = "${name}";
  cfg = config.services."${name}";
in {

  options = {
    services."${name}".enable = lib.options.mkEnableOption "${name}"; 
  };

  config = with config.networking; lib.mkIf cfg.enable {

    virtualisation.oci-containers.containers."${name}" = {
      image = "traefik/whoami";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.${name}.rule=Host(`${sub}.${hostName}.${domain}`) || Host(`${sub}.local.${domain}`)"
        "--label=traefik.http.routers.${name}.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.${name}.middlewares=basicauth@file"
      ];
      environmentFiles = [ config.age.secrets.self-env.path ];
      environment = {
        JONNY = "super awesome";
        MYPORT = "$SELF_SMTP_PORT";
      };
    };

  }; 

}
