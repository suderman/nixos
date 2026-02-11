# config.programs.openclaw.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.programs.openclaw;
  inherit (lib) mkIf mkAfter;

  openclawEnv =
    # sh
    ''
      export OPENCLAW_GATEWAY_HOST=${cfg.host}
      export OPENCLAW_GATEWAY_PORT=${toString cfg.port}
      if [[ -f /run/openclaw/gateway ]]; then
        export OPENCLAW_GATEWAY_TOKEN=$(cat /run/openclaw/gateway)
      fi
    '';
in {
  options.programs.openclaw = {
    enable = lib.mkEnableOption "openclaw";
    package = lib.mkOption {
      type = lib.types.package;
      default = perSystem.llm-agents.openclaw;
    };
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "bot.kit";
      description = "Host running the OpenClaw gateway";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 18789;
      description = "Port the OpenClaw gateway is listening to";
    };
  };
  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    programs = {
      bash.profileExtra = lib.mkAfter openclawEnv;
      zsh.envExtra = lib.mkAfter openclawEnv;

      zsh.initContent =
        mkAfter
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
