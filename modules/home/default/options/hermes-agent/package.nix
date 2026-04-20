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

          if [[ -z "''${HERMES_HOME:-}" ]]; then
            printf >&2 'HERMES_HOME is not set. Managed Hermes agents live under %s/<name>.\n' "${config.home.homeDirectory}/${cfg.dataDir}"
            exit 1
          fi

          mkdir -p "$HERMES_HOME"

          set -a
          [[ -f "${envKey}" ]] && . "${envKey}"
          [[ -f "$HERMES_HOME/.env.base" ]] && . "$HERMES_HOME/.env.base"
          [[ -f "$HERMES_HOME/.env" ]] && . "$HERMES_HOME/.env"
          set +a

          exec "${cfg.basePackage}/bin/hermes" "$@"
        '';
    };
  };
}
