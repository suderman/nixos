# config.programs.openclaw.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.programs.openclaw;
in {
  options.programs.openclaw = {
    enable = lib.mkEnableOption "openclaw";
    package = lib.mkOption {
      type = lib.types.package;
      default = perSystem.llm-agents.openclaw;
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
      default = 443;
      description = "Port the OpenClaw gateway is listening to";
    };
    # automatically set
    seed = lib.mkOption {
      type = lib.types.str;
      default =
        if cfg.host != "127.0.0.1"
        then cfg.host
        else config.services.openclaw.host;
    };
  };
  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    programs = let
      runDir = "/run/user/${toString config.home.uid}/openclaw";
      openclawEnv =
        # sh
        ''
          export OPENCLAW_GATEWAY_HOST=${cfg.host}
          export OPENCLAW_GATEWAY_PORT=${toString cfg.port}
          if [[ -f ${runDir}/gateway ]]; then
            export OPENCLAW_GATEWAY_TOKEN=$(cat ${runDir}/gateway)
          fi
        '';
    in {
      # OpenClaw CLI with host/port/token set
      bash.profileExtra = lib.mkAfter openclawEnv;
      zsh.envExtra = lib.mkAfter openclawEnv;

      # OpenClaw completions
      zsh.initContent =
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
  };
}
