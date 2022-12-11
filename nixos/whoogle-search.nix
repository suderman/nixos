{ inputs, config, pkgs, lib, ... }: 
  
let 

  labels = { name, auth ? false, ... }: [
    "--label=traefik.enable=true"
    "--label=traefik.http.routers.${name}.rule=Host(`${name}.${config.networking.hostName}.${config.networking.domain}`) || Host(`${name}.local.${config.networking.domain}`)"
    "--label=traefik.http.routers.${name}.tls.certresolver=resolver-dns"
  ] ++ (if auth == "basic" then ["--label=traefik.http.routers.${name}.middlewares=basicauth@file"] else []);

in {

  virtualisation.oci-containers.containers."whoogle-search" = {
    image = "benbusby/whoogle-search";
    # ports = [ "5000:5000" ]; #server locahost : docker localhost
    extraOptions = labels { name = "whoogle-search"; };
  };

  virtualisation.oci-containers.containers."hello" = {
    image = "traefik/whoami";
    extraOptions = labels { name = "hello"; auth = "basic"; };
    environmentFiles = [ config.age.secrets.self-env.path ];
    environment = {
      JONNY = "super awesome";
    };
  };

}
