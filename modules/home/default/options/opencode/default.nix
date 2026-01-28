# programs.opencode.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.programs.opencode;
  inherit (lib) mkIf;
in {
  config = mkIf cfg.enable {
    home.sessionVariables = {
      OPENCODE_MODEL = "openai/gpt-5.2-codex";
      OPENCODE_SUBAGENT_MODEL = "openai/gpt-5.1-codex-mini";
    };

    home.shellAliases = rec {
      oc = "opencode";
      occ = "${oc} --continue";
    };

    age.secrets = {
      openrouter.rekeyFile = ./openrouter.age; # provider
      zen.rekeyFile = ./zen.age; # provider
      smithery.rekeyFile = ./smithery.age; # exa mpc
    };

    programs.opencode = {
      enableMcpIntegration = true;
      rules = ./AGENTS.md;
      package = perSystem.llm-agents.opencode;
      settings = let
        file = path: "{file:${path}}";
        env = env: "{env:${env}}";
      in {
        autoshare = false;
        autoupdate = false;

        provider = {
          openrouter.options.apiKey = file config.age.secrets.openrouter.path;
          opencode.options.apiKey = file config.age.secrets.zen.path;
        };

        keybinds = {
          model_list = "ctrl+j";
          session_list = "ctrl+k";
          input_newline = "shift+return,alt+return";
          editor_open = "ctrl+o,<leader>e";
        };

        model = env "OPENCODE_MODEL";
        agent.general = {
          mode = "subagent";
          model = env "OPENCODE_SUBAGENT_MODEL";
        };
        agent.explore = {
          mode = "subagent";
          model = env "OPENCODE_SUBAGENT_MODEL";
        };
        permission.bash = {
          "curl" = "allow";
          "git commit" = "ask";
          "git push" = "ask";
          "nix eval" = "allow";
          "nixos-rebuild" = "deny";
        };
        mcp.gh_grep = {
          type = "remote";
          url = "https://mcp.grep.app";
        };
        mcp.exa = {
          type = "remote";
          url = "https://mcp.exa.ai/mcp?exaApiKey=${file config.age.secrets.smithery.path}";
          enabled = true;
        };
        mcp.context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
        };
      };
    };

    xdg.configFile = {
      "opencode/agents".source = ./agents;
      "opencode/commands".source = ./commands;
      "opencode/skills".source = ./skills;
      "opencode/tools".source = ./tools;
    };

    persist.storage.directories = [".local/share/opencode"];
  };
}
