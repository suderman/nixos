# config.programs.openclaw.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.openclaw;
  inherit (config.lib.openclaw) path port runDir;

  openclaw-env =
    if config.services.openclaw.apiKeys != null
    then ''
      cat ${config.age.secrets.openclaw-env.path} >>${runDir}/openclaw.env
    ''
    else "";

  openclaw-init = pkgs.self.mkScript {
    name = "openclaw";
    path = [pkgs.jq pkgs.json-repair];
    text =
      # bash
      ''
        export PATH=${lib.concatStringsSep ":" path}:"$PATH"
        export OPENCLAW_HOME="''${OPENCLAW_HOME:-${config.home.homeDirectory}}"
        export OPENCLAW_STATE_DIR="''${OPENCLAW_STATE_DIR:-${config.home.homeDirectory}/${cfg.dataDir}}"
        export OPENCLAW_CONFIG_PATH="''${OPENCLAW_CONFIG_PATH:-${config.home.homeDirectory}/${cfg.dataDir}/openclaw.json}"
        export OPENCLAW_GATEWAY_PORT="''${OPENCLAW_GATEWAY_PORT:-${toString cfg.port}}"
        export OPENCLAW_BIN="''${OPENCLAW_BIN:-${config.home.homeDirectory}/.local/share/npm/bin/openclaw}"

        # Initizalize OpenClaw: install via npm and create a ready gateway config with secrets
        openclaw_init() {

          # Install/update openclaw globally
          # npm already enabled via toolchains.javascript.enable = true;
          npm i -g openclaw

          # Ensure OpenClaw is actually installed
          if [[ ! -f $OPENCLAW_BIN ]]; then
            echo "Failed to install openclaw"
            exit 1
          fi

          # If host isn't 127.0.0.1, configure cli as client for remote
          if [[ "${cfg.host}" != "127.0.0.1" ]]; then
            $OPENCLAW_BIN onboard \
              --non-interactive --accept-risk \
              --mode remote \
              --remote-token  $(tr -d '\n' <${runDir}/gateway) \
              --remote-url=wss://${cfg.host}:${toString cfg.port}

          # Otherwise, configure as a gateway server
          else

            # Generate gateway override for openclaw.json
            {
              echo '{'
              echo '"gateway": {'
              echo '  "port": ${toString cfg.port},'
              echo '  "mode": "local",'
              echo '  "bind": "loopback",'
              echo '  "auth": { "mode": "token", "token": "\''${OPENCLAW_GATEWAY_TOKEN}" },'
              echo '  "trustedProxies": ["127.0.0.1", "${config.networking.address}"],'
              echo '  "controlUi": { "allowedOrigins": ["https://${cfg.host}"] }'
              echo '}'
            }>${runDir}/openclaw-gateway.json
            chmod 600 ${runDir}/openclaw-gateway.json

            # Generate dotenv with gateway token
            {
              echo "# OpenClaw Gateway URLs"
              echo "# http://localhost:${toString cfg.port}?token=$(tr -d '\n' <${runDir}/gateway)"
              echo "# https://${cfg.host}?token=$(tr -d '\n' <${runDir}/gateway)"
              echo "OPENCLAW_GATEWAY_TOKEN=$(tr -d '\n' <${runDir}/gateway)"
            }>${runDir}/openclaw.env
            chmod 600 ${runDir}/openclaw.env

            # Include API keys (if any) and copy to ~/openclaw/.env
            ${openclaw-env}
            install -dm700 $OPENCLAW_STATE_DIR
            cp -fp ${runDir}/openclaw.env $OPENCLAW_STATE_DIR/.env

            # Merge the override into OpenClaw's config json
            openclaw setup
            if [[ -f $OPENCLAW_CONFIG_PATH ]]; then

              # Base json (comments removed)
              json_repair $OPENCLAW_CONFIG_PATH >${runDir}/openclaw-base.json
              chmod 600 ${runDir}/openclaw-base.json

              # Merged json (mixing gateway into base)
              {
                jq '.gateway = input.gateway' ${runDir}/openclaw-base.json ${runDir}/openclaw-gateway.json
              } >${runDir}/openclaw.json
              chmod 600 ${runDir}/openclaw.json

              # Replace original config with merged
              mv ${runDir}/openclaw.json "$OPENCLAW_CONFIG_PATH"

            fi
          fi
        }

        # If argument is "init", run the above script
        if [[ "''${@-}" == "init" ]]; then
          openclaw_init

        # Else, if the config or binary is missing, run the above script first
        elif [[ ! -f $OPENCLAW_CONFIG_PATH ]] || [[ ! -f $OPENCLAW_BIN ]]; then
          openclaw_init
          $OPENCLAW_BIN "$@"

        # Otherwise, just passthrough to openclaw
        else
          $OPENCLAW_BIN "$@"
        fi
      '';
  };
in {
  options.programs.openclaw = {
    enable = lib.mkEnableOption "openclaw";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = ".openclaw";
    };
    # set this if using openclaw program without service
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "bot.kit";
      description = "Host running the OpenClaw gateway";
    };
    # automatically set
    port = lib.mkOption {
      type = lib.types.port;
      default = port;
      description = "Port the OpenClaw gateway is listening to";
    };
  };
  config = lib.mkIf cfg.enable {
    persist.storage.directories = [cfg.dataDir];

    # Install OpenClaw from npm and run with nodejs
    toolchains.javascript.enable = true;

    home.packages = [openclaw-init];

    # Configure OpenClaw CLI for remote (if host isn't 127.0.0.1)
    # systemd.user.services.openclaw-onboard = {
    #   Unit = {
    #     Description = "OpenClaw Gateway Setup";
    #     After = ["agenix.service"];
    #     Requires = ["agenix.service"];
    #   };
    #   Service = {
    #     Type = "oneshot";
    #     Environment = [
    #       "OPENCLAW_HOME=${config.home.homeDirectory}"
    #       "OPENCLAW_STATE_DIR=${config.home.homeDirectory}/${cfg.dataDir}"
    #       "OPENCLAW_CONFIG_PATH=${config.home.homeDirectory}/${cfg.dataDir}/openclaw.json"
    #     ];
    #     ExecStart = perSystem.self.mkScript {
    #       text =
    #         # bash
    #         ''
    #           if [[ "${cfg.host}" != "127.0.0.1" ]]; then
    #             openclaw onboard \
    #               --non-interactive --accept-risk \
    #               --mode remote \
    #               --remote-token  $(tr -d '\n' <${runDir}/gateway) \
    #               --remote-url=wss://${cfg.host}:${toString cfg.port}
    #           fi
    #         '';
    #       path = [cfg.package];
    #     };
    #   };
    #   Install.WantedBy = ["default.target"];
    # };

    # OpenClaw completions
    programs.zsh.initContent =
      lib.mkAfter
      # sh
      ''
        # OpenClaw completions (generate once, async)
        _openclaw_comp="$ZDOTDIR/openclaw"

        if [[ -r "$_openclaw_comp" ]]; then
          source "$_openclaw_comp"
        else
          {
            openclaw completion --shell zsh >| "$_openclaw_comp" 2>/dev/null
          } &!
        fi
      '';
  };
  # };
}
