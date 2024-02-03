# modules.whoogle.enable = true;
{ config, lib, this, ... }:
  
let 

  # https://github.com/benbusby/whoogle-search/releases
  version = "0.8.4";

  cfg = config.modules.whoogle;
  inherit (lib) mkIf mkOption mkBefore types;
  inherit (this.lib) traefikLabels;

in {

  options.modules.whoogle = {
    enable = lib.options.mkEnableOption "whoogle"; 
    hostName = mkOption {
      type = types.str;
      default = "whoogle.${this.hostName}";
    };
  };

  config = mkIf cfg.enable {

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Configure OCI container
    virtualisation.oci-containers.containers."whoogle" = {
      image = "benbusby/whoogle-search:${version}";
      extraOptions = traefikLabels cfg.hostName;
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
