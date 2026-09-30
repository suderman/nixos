# programs.hermes.enable = true;
{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.hermes;
  home = "${config.home.homeDirectory}/.hermes";
  wrapper = pkgs.self.mkScript {
    name = "hermes";
    text = ''
      export HERMES_HOME="''${HERMES_HOME:-${home}}"
      export SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
      export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt
      unset HERMES_MANAGED HASS_TOKEN HASS_URL
      exec ${cfg.package}/bin/hermes "$@"
    '';
  };
in {
  options.programs.hermes = {
    enable = lib.mkEnableOption "Hermes CLI";
    package = lib.mkOption {
      type = lib.types.package;
      default = perSystem.agents.hermes-agent;
      description = "Stock Hermes package.";
    };
    apiKeys = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Encrypted dotenv containing API keys.";
    };
  };

  config = lib.mkIf cfg.enable {
    persist.storage.directories = [
      {
        directory = ".hermes";
        mode = "0700";
      }
    ];
    home.packages = [wrapper];

    home.activation.hermesAgentConfiguration = lib.hm.dag.entryAfter ["agentConfigurationCheckout"] ''
      $DRY_RUN_CMD env \
        PATH=${lib.makeBinPath [pkgs.bash pkgs.coreutils]}:$PATH \
        HERMES_HOME=${home} \
        ${config.home.homeDirectory}/.agents/hermes/bootstrap
    '';

    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      hermes-env.rekeyFile = cfg.apiKeys;
    };

    systemd.user.services.hermes-agent-env = let
      keysEnv =
        if cfg.apiKeys != null
        then config.age.secrets.hermes-env.path
        else "/dev/null";
    in {
      Unit = {
        Description = "Generate Hermes dotenv";
        Requires = lib.optionals (cfg.apiKeys != null) ["agenix.service"];
        After = lib.optionals (cfg.apiKeys != null) ["agenix.service"];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
        ExecStart = pkgs.self.mkScript {
          text = ''
            set -eu
            umask 077
            mkdir -p "${home}"
            tmp="$(mktemp "${home}/.env.tmp.XXXXXX")"
            trap 'rm -f "$tmp"' EXIT
            if [ ! -r "${keysEnv}" ]; then
              echo "Missing Hermes agenix env file: ${keysEnv}" >&2
              exit 1
            fi
            while IFS= read -r line || [ -n "$line" ]; do
              case "$line" in
                HASS_TOKEN=*|HASS_URL=*) continue ;;
              esac
              printf '%s\n' "$line"
            done <"${keysEnv}" >"$tmp"
            chmod 600 "$tmp"
            mv -fT "$tmp" "${home}/.env"
          '';
        };
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
