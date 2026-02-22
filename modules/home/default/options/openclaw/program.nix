# config.programs.openclaw.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.programs.openclaw;
  inherit (config.lib.openclaw) port runDir;
in {
  options.programs.openclaw = {
    enable = lib.mkEnableOption "openclaw";
    package = lib.mkOption {
      type = lib.types.package;
      default = perSystem.llm-agents.openclaw;
    };
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

    # Configure OpenClaw CLI for remote (if host isn't 127.0.0.1)
    systemd.user.services.openclaw-onboard = {
      Unit = {
        Description = "OpenClaw Gateway Setup";
        After = ["agenix.service"];
        Requires = ["agenix.service"];
      };
      Service = {
        Type = "oneshot";
        Environment = [
          "OPENCLAW_HOME=${config.home.homeDirectory}"
          "OPENCLAW_STATE_DIR=${config.home.homeDirectory}/${cfg.dataDir}"
          "OPENCLAW_CONFIG_PATH=${config.home.homeDirectory}/${cfg.dataDir}/openclaw.json"
        ];
        ExecStart = perSystem.self.mkScript {
          text =
            # bash
            ''
              if [[ "${cfg.host}" != "127.0.0.1" ]]; then
                openclaw onboard \
                  --non-interactive --accept-risk \
                  --mode remote \
                  --remote-token  $(tr -d '\n' <${runDir}/gateway) \
                  --remote-url=wss://${cfg.host}:${toString cfg.port}
              fi
            '';
          path = [cfg.package];
        };
      };
      Install.WantedBy = ["default.target"];
    };

    # Add OpenClaw CLI to path
    home.packages = [cfg.package];

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
