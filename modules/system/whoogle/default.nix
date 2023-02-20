# services.whoogle.enable = true;
{ inputs, config, pkgs, lib, ... }:
  
let 
  name = "whoogle"; 
  cfg = config.services.whoogle;

in {
  options = {
    services.whoogle.enable = lib.options.mkEnableOption "whoogle"; 
  };

  config = lib.mkIf cfg.enable {

    virtualisation.oci-containers.containers."whoogle" = with config.networking; {
      image = "benbusby/whoogle-search";
      # ports = [ "5000:5000" ]; #server locahost : docker localhost
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.whoogle.rule=Host(`search.${hostName}.${domain}`) || Host(`search.local.${domain}`)"
        "--label=traefik.http.routers.whoogle.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.whoogle.middlewares=local@file"
        "--stop-signal=SIGKILL"
      ];
    };

  }; 

}
