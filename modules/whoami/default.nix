# modules.whoami.enable = true;
{ config, lib, this, ... }:
  
let 

  cfg = config.modules.whoami;
  inherit (lib) mkIf mkOption types;
  inherit (config.modules) traefik;

in {

  options.modules.whoami = {
    enable = lib.options.mkEnableOption "whoami"; 
    name = mkOption {
      type = types.str;
      default = "whoami";
    };
  };

  config = mkIf cfg.enable {

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Configure OCI container
    virtualisation.oci-containers.containers."whoami" = {
      image = "traefik/whoami";
      cmd = [ "--port=2001" ];
      extraOptions = traefik.labels [ cfg.name 2001 ]
      ++ [ "--network=host" ];
    };

  }; 

}
