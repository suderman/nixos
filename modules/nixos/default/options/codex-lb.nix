# services.codex-lb.enable = true;
{
  config,
  lib,
  ...
}: let
  # https://github.com/Soju06/codex-lb/pkgs/container/codex-lb
  version = "1.12.0";

  cfg = config.services.codex-lb;
  inherit (lib) mkIf mkOption types;
  inherit (config.services.traefik.lib) mkHostName mkLabels;

  hostName = mkHostName cfg.name;
in {
  options.services.codex-lb = {
    enable = lib.options.mkEnableOption "codex-lb";

    name = mkOption {
      type = types.str;
      default = "codex-lb";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/codex-lb";
    };

    version = mkOption {
      type = types.str;
      default = version;
    };

    environment = mkOption {
      type = with types; attrsOf str;
      default = {};
    };
  };

  config = mkIf cfg.enable {
    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids."codex-lb" = 216;
    ids.gids."codex-lb" = 216;

    users.users."codex-lb" = {
      isSystemUser = true;
      group = "codex-lb";
      description = "codex-lb daemon user";
      home = cfg.dataDir;
      uid = config.ids.uids."codex-lb";
    };

    users.groups."codex-lb" = {
      gid = config.ids.gids."codex-lb";
    };

    # Run the container as the same uid/gid that owns the bind mount.
    tmpfiles.directories = [
      {
        target = cfg.dataDir;
        mode = 775;
        user = config.ids.uids."codex-lb";
        group = config.ids.gids."codex-lb";
      }
    ];
    persist.storage.directories = [cfg.dataDir];

    services.traefik.enable = true;

    virtualisation.oci-containers.containers."codex-lb" = {
      image = "ghcr.io/soju06/codex-lb:${cfg.version}";
      user = "${toString config.ids.uids."codex-lb"}:${toString config.ids.gids."codex-lb"}";
      ports = ["127.0.0.1:1455:1455"];

      environment =
        {
          CODEX_LB_DASHBOARD_BOOTSTRAP_TOKEN = "bootstrap";
          CODEX_LB_OAUTH_CALLBACK_HOST = "0.0.0.0";
          CODEX_LB_OAUTH_REDIRECT_URI = "http://localhost:1455/auth/callback";
        }
        // cfg.environment;

      volumes = ["${cfg.dataDir}:/var/lib/codex-lb"];

      extraOptions = mkLabels {
        inherit hostName;
        name = cfg.name;
        port = 2455;
      };
    };

    systemd.services.docker-codex-lb.preStart = lib.mkBefore ''
      install -d -m 0775 -o ${toString config.ids.uids."codex-lb"} -g ${toString config.ids.gids."codex-lb"} ${cfg.dataDir}
      chown -R ${toString config.ids.uids."codex-lb"}:${toString config.ids.gids."codex-lb"} ${cfg.dataDir}
    '';
  };
}
