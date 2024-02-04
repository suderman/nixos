# modules.rsshub.enable = true;
{ config, lib, pkgs, this, ... }:

let

  # https://hub.docker.com/r/diygod/rsshub/tags
  tag = "chromium-bundled";

  # https://docs.rsshub.app/en/install/#docker-compose-deployment-install
  cfg = config.modules.rsshub;

  inherit (lib) mkIf mkOption mkBefore options types strings;
  inherit (builtins) toString;
  inherit (lib.strings) toInt;

in {

  imports = [
    ./rsshub-redis.nix
    ./rsshub-web.nix
  ];

  options.modules.rsshub = {
    enable = options.mkEnableOption "rsshub"; 
    tag = mkOption {
      type = types.str;
      default = tag;
    };
    name = mkOption {
      type = types.str;
      default = "rsshub";
    };
  };

  config = mkIf cfg.enable {

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Init service
    systemd.services.rsshub = {
      enable = true;
      description = "rsshub";
      wantedBy = [ "multi-user.target" ];
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

    # # todo: replace mkdir with tmpfiles
    # systemd.tmpfiles.rules = [
    #   "d '${cfg.dataDir}' 0700 ${cfg.user} ${cfg.group} - -"
    # ];

  };

}
