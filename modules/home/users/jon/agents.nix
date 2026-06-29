{
  config,
  pkgs,
  ...
}: {
  # Preload OpenCode with my API keys
  programs.opencode.apiKeys = ./apikeys-env.age;

  # Preload mmx-cli with my API keys
  programs.mmx-cli.apiKeys = ./apikeys-env.age;

  # Preload pi with my API keys
  programs.pi-coding-agent.apiKeys = ./apikeys-env.age;

  # Set my API keys and preferred models for hermes agent
  services.hermes-agent = {
    apiKeys = ./apikeys-env.age;
    models = {
      minimax = extra:
        {
          provider = "minimax";
          model = "MiniMax-M3";
          base_url = "https://api.minimax.io/anthropic";
          api_key = "\${MINIMAX_API_KEY}";
        }
        // extra;
      gpt = extra:
        {
          provider = "custom";
          model = "gpt-5.5";
          base_url = "https://codex-lb.kit/v1";
          api_key = "\${CODEX_LB_API_KEY}";
          api_mode = "chat_completions";
        }
        // extra;
      gptmini = extra:
        {
          provider = "custom";
          model = "gpt-5.4-mini";
          base_url = "https://codex-lb.kit/v1";
          api_key = "\${CODEX_LB_API_KEY}";
          api_mode = "chat_completions";
        }
        // extra;
    };

    # Shared configuration
    config = let
      inherit (config.services.hermes-agent.models) minimax gptmini gpt;
    in {
      model = {
        inherit (minimax {}) provider base_url api_key;
        default = (minimax {}).model;
      };
      auxiliary = {
        # Image analysis (vision_analyze tool + browser screenshots)
        vision = minimax {
          timeout = 120;
          download_timeout = 30;
        };

        # Context compression timeout
        compression = minimax {
          timeout = 120;
        };

        # Web page summarization + browser page text extraction
        web_extract = minimax {
          timeout = 360;
        };

        # Smart command-approval classification
        approval = minimax {
          timeout = 30;
        };

        # Past session summarization
        session_search = minimax {
          timeout = 30;
          max_concurrency = 3;
        };

        # Skill search and discovery
        skills_hub = minimax {
          timeout = 30;
        };

        # MCP tool dispatch
        mcp = minimax {
          timeout = 30;
        };

        # Session title summaries
        title_generation = minimax {
          timeout = 30;
        };

        # Prune and tend to my skills garden
        curator = minimax {
          timeout = 600;
        };

        # Before session disappears, decide what should be remembered
        flush_memories = minimax {
          timeout = 30;
        };

        # Kanban triage specifier
        triage_specifier = minimax {
          timeout = 120;
        };
      };

      # Enable tools web_search and understand_image
      mcp_servers = {
        minimax = {
          command = "uvx";
          args = ["minimax-coding-plan-mcp" "-y"];
          env = {
            MINIMAX_API_KEY = (minimax {}).api_key;
            MINIMAX_API_HOST = "https://api.minimax.io";
          };
          tools = {
            prompts = false;
            resources = false;
          };
        };
      };
    };
  };

  # Self-hosted webapps running from my kit desktop
  xdg = config.desktop {
    desktopEntries = config.lib.chromium.mkWebApp {
      name = "OpenCode";
      url = "https://opencode-jon.kit";
      icon =
        pkgs.writeText "icon.svg"
        # html
        ''
          <svg width='300' height='300' viewBox='0 0 300 300' fill='none' xmlns='http://www.w3.org/2000/svg'><g transform='translate(30, 0)'><g clip-path='url(#clip0_1401_86283)'><mask id='mask0_1401_86283' style='mask-type:luminance' maskUnits='userSpaceOnUse' x='0' y='0' width='240' height='300'><path d='M240 0H0V300H240V0Z' fill='white'/></mask><g mask='url(#mask0_1401_86283)'><path d='M180 240H60V120H180V240Z' fill='#4B4646'/><path d='M180 60H60V240H180V60ZM240 300H0V0H240V300Z' fill='#F1ECEC'/></g></g></g><defs><clipPath id='clip0_1401_86283'><rect width='240' height='300' fill='white'/></clipPath></defs></svg>
        '';
    };
  };
}
