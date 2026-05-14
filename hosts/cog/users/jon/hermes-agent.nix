{...}: let
  minimax = extra:
    {
      provider = "minimax";
      model = "MiniMax-M2.7";
      base_url = "https://api.minimax.io/anthropic";
      api_key = "\${MINIMAX_API_KEY}";
    }
    // extra;
  gpt = extra:
    {
      provider = "custom";
      model = "gpt-5.4";
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
in {
  services.hermes-agent = {
    enable = true;

    # Shared configuration
    config = {
      model = {
        inherit (minimax {}) provider base_url api_key;
        default = (minimax {}).model;
      };
      auxiliary = {
        # Image analysis (vision_analyze tool + browser screenshots)
        vision = gptmini {
          timeout = 120;
          download_timeout = 30;
        };

        # Web page summarization + browser page text extraction
        web_extract = minimax {
          timeout = 360;
        };

        # Smart command-approval classification
        approval = minimax {
          timeout = 30;
        };

        # Context compression timeout
        compression = minimax {
          timeout = 120;
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

    # Agents and their configuration overrides
    agents = {
      watt.gateway = true;
      june.gateway = "kit";
      pax.gateway = "kit";
      cid.gateway = "kit";
      dot.client = "gem";
    };
  };

  # Ensure uvx is available for mcp servers
  toolchains.python.enable = true;
}
