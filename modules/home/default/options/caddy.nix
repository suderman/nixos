{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.caddy;
in {
  options.services.caddy = {
    enable = lib.mkEnableOption "caddy";
    package = lib.mkPackageOption pkgs "caddy" {};
    port = lib.mkOption {
      type = lib.types.port;
      default = 21000 + config.home.portOffset;
      description = "Port for Caddy to listen on (unprivileged).";
    };
  };

  config = lib.mkIf cfg.enable {
    persist.storage.directories = [".local/share/caddy" ".config/caddy"];

    home.packages = [cfg.package];

    systemd.user.services.caddy = {
      Unit = {
        Description = "Caddy web server";
        After = ["network.target"];
      };

      Service = let
        caddy = "${cfg.package}/bin/caddy";
        Caddyfile = "${config.home.homeDirectory}/.config/caddy/Caddyfile";
        CaddyTemplate = pkgs.writeText "Caddyfile.template" ''
          {
            auto_https off
            admin 127.0.0.1:${toString (cfg.port + 1)}
          }

          :${toString cfg.port} {
            handle /healthz {
              respond "ok" 200
            }

            handle {
              respond "Unknown app" 404
            }
          }
        '';
      in {
        ExecStartPre = pkgs.writeShellScript "caddy-init" ''
          mkdir -p "$(dirname ${Caddyfile})"
          if [[ ! -f "${Caddyfile}" ]]; then
            cp ${CaddyTemplate} "${Caddyfile}"
            chmod 644 "${Caddyfile}"
          fi
        '';
        ExecStart = "${caddy} run --config ${Caddyfile}";
        ExecReload = "${caddy} reload --config ${Caddyfile} --address 127.0.0.1:${toString (cfg.port + 1)}";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = ["XDG_DATA_HOME=${config.home.homeDirectory}/.local/share"];
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
