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

    # Create wrapper for openclaw with env variables set
    home.packages = [
      (perSystem.self.mkScript {
        name = "openclaw";
        text =
          # bash
          ''
            # Default gateway host (only if unset)
            if [[ -z "''${OPENCLAW_GATEWAY_HOST+x}" ]]; then
              export OPENCLAW_GATEWAY_HOST="${cfg.host}"
            fi

            # Default gateway port (only if unset)
            if [[ -z "''${OPENCLAW_GATEWAY_PORT+x}" ]]; then
              export OPENCLAW_GATEWAY_PORT="${toString cfg.port}"
            fi

            # Default gateway token from file (only if unset, and file exists)
            if [[ -z "''${OPENCLAW_GATEWAY_TOKEN+x}" && -f "${runDir}/gateway" ]]; then
              export OPENCLAW_GATEWAY_TOKEN="$(cat "${runDir}/gateway")"
            fi

            exec "${cfg.package}/bin/openclaw" "$@"
          '';
      })
    ];

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
