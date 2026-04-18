# services.hermes.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.hermes-agent;
  dir = "${config.home.homeDirectory}/${cfg.dataDir}";
in {
  config = lib.mkIf cfg.enable {
    services.hermes-agent.gatewaySyncPackage = pkgs.self.mkScript {
      name = "hermes-gateway-sync";
      path = [pkgs.python3 pkgs.systemd pkgs.gawk];
      text =
        # bash
        ''
          set -euo pipefail

          env_only=0
          if [[ "''${1:-}" == "--env-only" ]]; then
            env_only=1
          fi

          allocations="$(mktemp)"
          trap 'rm -f "$allocations"' EXIT
          mkdir -p "${dir}/profiles"

          python ${./gateway-sync.py} \
            "${dir}/profiles" \
            "${dir}/.env.base" \
            "${toString cfg.apiPort}" \
            "${toString cfg.dashboardPort}" \
            >"$allocations"

          desired_units=()

          while IFS=$'\t' read -r name _api_port _dashboard_port; do
            [[ -n "$name" ]] || continue
            desired_units+=("hermes-gateway@$name.service")

            if (( ! env_only )); then
              systemctl --user start "hermes-gateway@$name.service"
            fi
          done <"$allocations"

          if (( env_only )); then
            exit 0
          fi

          while read -r unit _; do
            [[ -n "$unit" ]] || continue
            case " ''${desired_units[*]} " in
              *" $unit "*) ;;
              *) systemctl --user stop "$unit" ;;
            esac
          done < <(systemctl --user list-units 'hermes-gateway@*.service' --all --plain --no-legend --no-pager | gawk '{print $1}')
        '';
    };

    home.activation.hermes-gateway =
      lib.hm.dag.entryAfter ["writeBoundary"]
      # bash
      ''
        ${cfg.gatewaySyncPackage}/bin/hermes-gateway-sync --env-only
        if ${pkgs.systemd}/bin/systemctl --user --quiet is-active default.target 2>/dev/null; then
          ${pkgs.systemd}/bin/systemctl --user restart hermes-gateway-sync.service || true
        fi
      '';

    systemd.user.services = let
      path =
        config.home.sessionPath
        ++ [
          "${config.home.profileDirectory}/bin"
          "/run/current-system/sw/bin"
          "/usr/bin"
          "/bin"
        ];
      mkService = attr:
        attr
        // {
          Restart = "always";
          RestartSec = 5;
          TimeoutStopSec = 30;
          TimeoutStartSec = 30;
          SuccessExitStatus = "0 143";
          KillMode = "control-group";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = false;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = false;
        };
    in {
      hermes-gateway = {
        Unit = {
          Description = "Hermes Agent Gateway";
          After = ["network-online.target" "agenix.service"];
          Requires = ["agenix.service"];
          Wants = ["network-online.target"];
        };

        Service = mkService {
          Type = "simple";
          Environment = [
            "PATH=${lib.concatStringsSep ":" path}"
            "HERMES_HOME=${dir}"
          ];
          # Hermes tracks gateway state itself, so `--replace` keeps systemd
          # restarts from failing when Hermes still sees an existing PID/state.
          ExecStart = "${cfg.package}/bin/hermes gateway run --replace";
        };

        Install.WantedBy = ["default.target"];
      };

      "hermes-gateway@" = {
        Unit = {
          Description = "Hermes Agent Gateway (%I)";
          After = ["network-online.target" "agenix.service"];
          Requires = ["agenix.service"];
          Wants = ["network-online.target"];
        };

        Service = mkService {
          Type = "simple";
          Environment = [
            "PATH=${lib.concatStringsSep ":" path}"
            "HERMES_HOME=${dir}/profiles/%I"
          ];
          ExecStart = "${cfg.package}/bin/hermes gateway run --replace";
        };
      };

      hermes-gateway-sync = {
        Unit = {
          Description = "Hermes Agent Gateway Profile Sync";
          After = ["network-online.target" "agenix.service"];
          Requires = ["agenix.service"];
          Wants = ["network-online.target"];
        };

        Service = {
          Type = "oneshot";
          Environment = ["PATH=${lib.concatStringsSep ":" path}"];
          ExecStart = "${cfg.gatewaySyncPackage}/bin/hermes-gateway-sync";
        };

        Install.WantedBy = ["default.target"];
      };
    };
  };
}
