# services.whoami.enable = true;
{ config, lib, this, ... }:
  
let 

  cfg = config.services.whoami;
  inherit (lib) mkIf mkOption types;
  inherit (config.services.traefik.lib) mkLabels;

in {

  options.services.whoami = {
    enable = lib.options.mkEnableOption "whoami"; 
    name = mkOption {
      type = types.str;
      default = "whoami";
    };
  };

  config = mkIf cfg.enable {

    # Enable reverse proxy
    services.traefik.enable = true;

    # Configure OCI container
    virtualisation.oci-containers.containers."whoami" = {
      image = "traefik/whoami";
      cmd = [ "--port=2001" ];
      extraOptions = mkLabels [ cfg.name 2001 ]
      ++ [ "--network=host" ];
    };

  }; 

}
