# services.attic.enable = true;
#
# Bootstrap on the server after first deploy:
#   sudo atticd-atticadm make-token --sub "jon" --validity "12 months" --pull '*' --push '*' --delete '*' --create-cache '*' --configure-cache '*' --configure-cache-retention '*' --destroy-cache '*'
#   attic login local https://attic.kit <token> --set-default
#   attic cache create main
#   attic cache info main
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.attic;
  inherit
    (lib)
    getExe
    mkBefore
    mkDefault
    mkForce
    mkIf
    mkOption
    types
    ;
  inherit (config.services.traefik.lib) mkHostName;

  hostName = mkHostName cfg.name;
in {
  options.services.attic = {
    enable = lib.options.mkEnableOption "attic binary cache";

    name = mkOption {
      type = types.str;
      default = "attic";
    };

    port = mkOption {
      type = types.port;
      default = 8084;
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/atticd";
    };

    environmentFile = mkOption {
      type = types.path;
      default = "${cfg.dataDir}/server-token.env";
    };

    public = mkOption {
      type = types.bool;
      default = false;
    };

    extraHostNames = mkOption {
      type = with types; listOf str;
      default = [];
    };
  };

  config = mkIf cfg.enable {
    users.groups.atticd = {};
    users.users.atticd = {
      isSystemUser = true;
      group = "atticd";
      home = cfg.dataDir;
      createHome = false;
    };

    services.traefik = {
      enable = true;
      proxy.${cfg.name} = {
        url = "http://127.0.0.1:${toString cfg.port}";
        inherit (cfg) public;
      };
    };

    services.atticd = {
      enable = true;
      environmentFile = mkDefault cfg.environmentFile;
      settings.listen = mkDefault "127.0.0.1:${toString cfg.port}";
      settings.api-endpoint = mkDefault "https://${hostName}/";
      settings.allowed-hosts = mkDefault ([
          hostName
          "127.0.0.1:${toString cfg.port}"
          "localhost:${toString cfg.port}"
        ] ++ cfg.extraHostNames);
      settings.require-proof-of-possession = mkDefault false;
      settings.database.url = mkDefault "sqlite://${cfg.dataDir}/server.db?mode=rwc";
      settings.storage = mkDefault {
        type = "local";
        path = "${cfg.dataDir}/storage";
      };
    };

    systemd.services.atticd.serviceConfig.DynamicUser = mkForce false;

    system.activationScripts.atticdToken = mkBefore ''
      install -d -m 0700 ${cfg.dataDir}

      if [ ! -s ${cfg.environmentFile} ]; then
        (
          umask 0077
          ${getExe pkgs.openssl} genrsa -traditional 4096 \
            | ${pkgs.coreutils}/bin/base64 -w0 \
            | ${pkgs.gnused}/bin/sed 's/^/ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=/' \
            > ${cfg.environmentFile}
        )
      fi
    '';

    persist.storage.directories = [cfg.dataDir];

    environment.systemPackages = [pkgs.attic-client];
  };
}
