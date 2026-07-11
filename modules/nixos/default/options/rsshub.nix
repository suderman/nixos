# services.rsshub.enable = true;
{
  config,
  flake,
  lib,
  pkgs,
  ...
}: let
  # https://docs.rsshub.app/en/install/#docker-compose-deployment-install
  cfg = config.services.rsshub;

  inherit (config.services.traefik.lib) mkLabels;
  inherit (lib) mkIf mkOption options types;
in {
  disabledModules = ["services/web-apps/rsshub.nix"];
  options.services.rsshub = {
    enable = options.mkEnableOption "rsshub";
    tag = mkOption {
      type = types.str;
      default = flake.inputs.pins.default.containers.rsshub.tag;
    };
    name = mkOption {
      type = types.str;
      default = "rsshub";
    };
  };

  config = mkIf cfg.enable {
    # Enable reverse proxy
    services.traefik.enable = true;

    # Init service
    systemd.services.rsshub = {
      enable = true;
      description = "rsshub";
      wantedBy = ["multi-user.target"];
      before = [
        "docker-rsshub-redis.service"
        "docker-rsshub-web.service"
      ];
      wants = config.systemd.services.rsshub.before;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      script = ''
        sleep 5
        #
        # Ensure docker network exists
        ${pkgs.docker}/bin/docker network create rsshub 2>/dev/null || true
      '';
    };

    # Web front-end
    virtualisation.oci-containers.containers.rsshub-web = let
      pin = flake.inputs.pins.default.containers.rsshub;
    in {
      image =
        if cfg.tag == pin.tag
        then pin.image
        else "diygod/rsshub:${cfg.tag}";
      autoStart = false;

      # Environment variables
      environment = {
        NODE_ENV = "production";
        CACHE_TYPE = "redis";
        REDIS_URL = "redis://redis:6379/";
      };

      # Traefik labels
      extraOptions =
        mkLabels cfg.name
        # Networking for docker containers
        ++ ["--network=rsshub"];
    };

    # Extend systemd service
    systemd.services.docker-rsshub-web = {
      requires = ["rsshub.service"];
    };

    # Redis cache
    virtualisation.oci-containers.containers.rsshub-redis = {
      image = flake.inputs.pins.default.containers.rsshub-redis.image;
      autoStart = false;

      # Map volumes to host
      volumes = ["rsshub-redis:/data"];

      # Networking for docker containers
      extraOptions = [
        "--network=rsshub"
      ];
    };

    # Extend systemd service
    systemd.services.docker-rsshub-redis = {
      requires = ["rsshub.service"];
    };
  };
}
