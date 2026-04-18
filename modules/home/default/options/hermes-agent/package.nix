{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.hermes-agent;
in {
  config = lib.mkIf cfg.enable {
    services.hermes-agent.package = pkgs.self.mkScript {
      name = "hermes";
      text = let
        pythonPath = with pkgs.python3.pkgs;
          makePythonPath [python-telegram-bot fastapi uvicorn];
        envKey = "/run/hermes/${toString config.home.uid}/key.env";
      in
        # bash
        ''
          export PYTHONPATH="${pythonPath}:''${PYTHONPATH:-}"
          export HERMES_HOME="''${HERMES_HOME:-${config.home.homeDirectory}/${cfg.dataDir}}"
          mkdir -p "$HERMES_HOME"

          set -a
          [[ -f "${envKey}" ]] && . "${envKey}"
          [[ -f "$HERMES_HOME/.env.base" ]] && . "$HERMES_HOME/.env.base"
          [[ -f "$HERMES_HOME/.env" ]] && . "$HERMES_HOME/.env"
          set +a

          exec "${cfg.basePackage}/bin/hermes" "$@"
        '';
    };

    home.activation.hermes-env = let
      dir = "${config.home.homeDirectory}/${cfg.dataDir}";
      baseEnv =
        pkgs.writeText "hermes-base.env"
        # sh
        ''
          API_SERVER_ENABLED=1
          API_SERVER_PORT=${toString cfg.apiPort}
          DASHBOARD_PORT=${toString cfg.dashboardPort}
        '';
      keysEnv =
        if cfg.apiKeys != null
        then "${config.age.secrets.hermes-env.path}"
        else "/dev/null";
    in
      lib.hm.dag.entryAfter ["writeBoundary"]
      # bash
      ''
        mkdir -p ${dir}
        cat "${baseEnv}" >${dir}/.env.base
        if [[ -f "${keysEnv}" ]]; then
          echo >>${dir}/.env.base
          cat "${keysEnv}" >>${dir}/.env.base
        fi
        chmod 600 ${dir}/.env.base
      '';
  };
}
