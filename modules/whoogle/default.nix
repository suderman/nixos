# services.whoogle.enable = true;
{ config, lib, this, ... }:
  
let 

  # https://github.com/benbusby/whoogle-search/releases
  version = "0.8.4";

  cfg = config.services.whoogle;
  inherit (lib) mkIf mkOption mkBefore types;
  inherit (config.services.traefik.lib) mkLabels;

in {

  options.services.whoogle = {
    enable = lib.options.mkEnableOption "whoogle"; 
    name = mkOption {
      type = types.str;
      default = "whoogle";
    };
  };

  config = mkIf cfg.enable {

    # Enable reverse proxy
    services.traefik.enable = true;

    # Configure OCI container
    virtualisation.oci-containers.containers."whoogle" = {
      image = "benbusby/whoogle-search:${version}";
      extraOptions = mkLabels cfg.name;
    };

    # Extend systemd service
    systemd.services.docker-whoogle = {
      after = [ "traefik.service" ];
      requires = [ "traefik.service" ];
      preStart = with config.virtualisation.oci-containers.containers; ''
        docker pull ${whoogle.image};
      '';
      # Container will not stop gracefully, so kill it
      serviceConfig = {
        KillSignal = "SIGKILL";
        SuccessExitStatus = "0 SIGKILL";
      };
    };

  }; 

}
