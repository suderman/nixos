# config.programs.openclaw.enable = true;
{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.openclaw;
  inherit (lib) mkIf mkAfter options;
  dataDir = ".openclaw"; # default config & state directory for OpenClaw
in {
  options.programs.openclaw = {
    enable = options.mkEnableOption "openclaw";
  };
  config = mkIf cfg.enable ({
      home.sessionVariables = {
        OPENCLAW_STATE_DIR = "${config.home.homeDirectory}/${dataDir}";
        OPENCLAW_CONFIG_PATH = "${config.home.homeDirectory}/${dataDir}/openclaw.json";
        # OPENCLAW_GATEWAY_PORT
        # OPENCLAW_GATEWAY_TOKEN
      };
      persist.storage.directories = [dataDir];
      home.packages = [
        perSystem.llm-agents.openclaw
      ];
      programs.zsh.initContent =
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
    }
    // {
      # home.sessionVariables = {
      #   PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
      # };
      # home.sessionPath = [
      #   "${config.home.homeDirectory}/.local/share/pnpm"
      # ];
      # persist.scratch.directories = [".local/share/pnpm"];
      # home.packages = [
      #   pkgs.nodejs_24
      #   pkgs.pnpm
      # ];
    });
}
