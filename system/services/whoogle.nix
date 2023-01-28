{ inputs, config, pkgs, lib, ... }:
  
let 
  name = "whoogle"; 
  sub = "search";
  cfg = config.services."${name}";

in {
  options = {
    services."${name}".enable = lib.options.mkEnableOption "${name}"; 
  };

  # services.whoogle.enable = true;
  config = with config.networking; lib.mkIf cfg.enable {

    virtualisation.oci-containers.containers."${name}" = {
      image = "benbusby/whoogle-search";
      # ports = [ "5000:5000" ]; #server locahost : docker localhost
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.${name}.rule=Host(`${sub}.${hostName}.${domain}`) || Host(`${sub}.local.${domain}`)"
        "--label=traefik.http.routers.${name}.tls.certresolver=resolver-dns"
        "--stop-signal=SIGKILL"
      ];
    };

  }; 

}
