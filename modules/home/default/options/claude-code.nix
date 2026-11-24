# programs.claude-code.enable = true;
{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.claude-code;
  # Where June keeps numbered logins (claude1, claude2) she holds the claude name and picks the account.
  juneOwns = config.programs.june.accounts.enable or false;
  launchClaude = ''
    # Keep the daemon entrypoint and caller-selected permissions intact.
    if [[ ''${1-} == daemon ]]; then
      exec ${lib.getExe cfg.package} "$@"
    fi
    for arg in "$@"; do
      case "$arg" in
        --permission-mode|--permission-mode=*|--dangerously-skip-permissions|--allow-dangerously-skip-permissions)
          exec ${lib.getExe cfg.package} "$@" ;;
        --) break ;;
      esac
    done
    exec ${lib.getExe cfg.package} --permission-mode bypassPermissions "$@"
  '';
in {
  config = lib.mkIf cfg.enable {
    programs.claude-code.package = lib.mkDefault perSystem.agents.claude-code;

    # Keep settings and login state writable and owned by Claude and agents apply.
    persist.storage = {
      directories = [
        {
          directory = ".claude";
          mode = "0700";
        }
        {
          directory = ".local/state/claude";
          mode = "0700";
        }
      ];
      files = [".claude.json"];
    };

    home.file.".local/bin/claude" = lib.mkIf (!juneOwns) {
      source = config.home.file.".local/bin/claude-direct".source;
    };

    # June's numbered wrappers run this launcher: proxy settings cleared, bypass-permissions default kept, and
    # CLAUDE_CONFIG_DIR left to the wrapper.
    home.file.".local/libexec/june/claude" = lib.mkIf juneOwns {
      source = config.home.file.".local/bin/claude-direct".source;
    };

    home.file.".local/bin/claude-direct".source = lib.getExe (pkgs.self.mkScript {
      name = "claude-direct";
      text =
        # bash
        ''
          unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY \
            CLAUDE_CODE_OAUTH_TOKEN ANTHROPIC_MODEL \
            CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY ENABLE_CLAUDEAI_MCP_SERVERS

          ${launchClaude}
        '';
    });
  };
}
