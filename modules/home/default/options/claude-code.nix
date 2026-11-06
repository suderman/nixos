# programs.claude-code.enable = true;
{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.claude-code;

  wrapper = pkgs.self.mkScript {
    name = "claude";
    text =
      # bash
      ''
        set -a
        . ${lib.escapeShellArg cfg.environmentFile}
        set +a

        export ANTHROPIC_BASE_URL=https://cliproxyapi.kit
        export ANTHROPIC_AUTH_TOKEN="''${CLIPROXYAPI_API_KEY:?Missing CLIPROXYAPI_API_KEY in Claude environment file}"
        export ANTHROPIC_MODEL=claude-opus-5-5
        export CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1
        export ENABLE_CLAUDEAI_MCP_SERVERS=false
        unset ANTHROPIC_API_KEY CLAUDE_CODE_OAUTH_TOKEN

        exec ${lib.getExe cfg.package} "$@"
      '';
  };
in {
  options.programs.claude-code.environmentFile = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Decrypted shell-compatible dotenv containing CLIPROXYAPI_API_KEY. Enables the CLIProxyAPI launcher when set.";
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code.package = lib.mkDefault perSystem.agents.claude-code;

    # Keep settings and login state writable and owned by Claude and agents apply.
    persist.storage = {
      directories = [
        {
          directory = ".claude";
          mode = "0700";
        }
      ];
      files = [".claude.json"];
    };

    home.file.".local/bin/claude" = lib.mkIf (cfg.environmentFile != null) {
      source = "${wrapper}/bin/claude";
    };

    home.file.".local/bin/claude-direct".source = lib.getExe (pkgs.self.mkScript {
      name = "claude-direct";
      text =
        # bash
        ''
          unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY \
            CLAUDE_CODE_OAUTH_TOKEN ANTHROPIC_MODEL \
            CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY ENABLE_CLAUDEAI_MCP_SERVERS

          exec ${lib.getExe cfg.package} "$@"
        '';
    });
  };
}
