{
  config,
  lib,
  pkgs,
  ...
}: let
  agentConfigurationCheckout = pkgs.writeShellApplication {
    name = "agent-configuration-checkout";
    runtimeInputs = [pkgs.coreutils pkgs.git];
    text = ''
      repository="$HOME/.agents"
      remote=https://github.com/suderman/agents.git
      legacy_skills="''${XDG_STATE_HOME:-$HOME/.local/state}/agents/legacy-skills"

      clone_replacing_symlink() {
        local temporary

        temporary="$(mktemp -d "$HOME/.agents.checkout.XXXXXX")"
        trap 'rm -rf -- "$temporary"' RETURN
        git clone "$remote" "$temporary"
        rm -- "$repository"
        mv -T -- "$temporary" "$repository"
        trap - RETURN
      }

      retire_legacy_skills_checkout() {
        local entries

        shopt -s nullglob dotglob
        entries=("$repository"/*)
        shopt -u nullglob dotglob
        [[ ''${#entries[@]} -eq 1 && "''${entries[0]}" == "$repository/skills" && -d "$repository/skills/.git" ]] || return 1

        if [[ -e "$legacy_skills" || -L "$legacy_skills" ]]; then
          echo "Cannot preserve legacy agent skills: $legacy_skills already exists" >&2
          exit 1
        fi

        mkdir -p -- "$(dirname -- "$legacy_skills")"
        mv -- "$repository/skills" "$legacy_skills"
        echo "Preserved legacy agent skills at $legacy_skills" >&2
      }

      if [[ -L "$repository" ]]; then
        resolved="$(readlink -f -- "$repository" || true)"
        if [[ ! -d "$resolved/.git" ]]; then
          echo "Refusing to replace agent configuration symlink: $repository -> $resolved" >&2
          exit 1
        fi
        clone_replacing_symlink
      elif [[ -d "$repository/.git" ]]; then
        :
      elif [[ ! -e "$repository" ]]; then
        git clone "$remote" "$repository"
      elif [[ -d "$repository" ]]; then
        retire_legacy_skills_checkout || true
        if [[ -n "$(ls -A "$repository")" ]]; then
          echo "Agent configuration directory is not empty: $repository" >&2
          exit 1
        fi
        git clone "$remote" "$repository"
      else
        echo "Agent configuration is not a Git checkout: $repository" >&2
        exit 1
      fi
    '';
  };
in {
  # Keep the complete curated configuration as one writable Git checkout.
  persist.storage.directories = [".agents"];

  home.activation.agentConfigurationCheckout = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${lib.getExe agentConfigurationCheckout}
  '';

  # Preload OpenCode with my API keys
  programs.opencode.apiKeys = ./apikeys-env.age;

  # Preload mmx-cli with my API keys
  programs.mmx-cli.apiKeys = ./apikeys-env.age;

  # Preload pi with my API keys and watch the downloads task drop zones.
  programs.pi-coding-agent = {
    apiKeys = ./apikeys-env.age;
    taskDropZones.enable = true;
  };

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
      gptsol = extra:
        {
          provider = "custom";
          model = "gpt-5.6-sol";
          base_url = "https://codex-lb.kit/v1";
          api_key = "\${CODEX_LB_API_KEY}";
          api_mode = "chat_completions";
        }
        // extra;
      gptterra = extra:
        {
          provider = "custom";
          model = "gpt-5.6-terra";
          base_url = "https://codex-lb.kit/v1";
          api_key = "\${CODEX_LB_API_KEY}";
          api_mode = "chat_completions";
        }
        // extra;
      gptluna = extra:
        {
          provider = "custom";
          model = "gpt-5.6-luna";
          base_url = "https://codex-lb.kit/v1";
          api_key = "\${CODEX_LB_API_KEY}";
          api_mode = "chat_completions";
        }
        // extra;
    };

    # Shared configuration
    config = let
      inherit (config.services.hermes-agent.models) minimax gptluna gptterra gptsol;
    in {
      model = {
        inherit (gptluna {}) provider base_url api_key;
        default = (gptluna {}).model;
      };
      auxiliary = {
        # Image analysis (vision_analyze tool + browser screenshots)
        vision = gptluna {
          timeout = 120;
          download_timeout = 30;
        };

        # Context compression timeout
        compression = gptluna {
          timeout = 120;
        };

        # Web page summarization + browser page text extraction
        web_extract = gptluna {
          timeout = 360;
        };

        # Smart command-approval classification
        approval = gptluna {
          timeout = 30;
        };

        # Past session summarization
        session_search = gptluna {
          timeout = 30;
          max_concurrency = 3;
        };

        # Skill search and discovery
        skills_hub = gptluna {
          timeout = 30;
        };

        # MCP tool dispatch
        mcp = gptluna {
          timeout = 30;
        };

        # Session title summaries
        title_generation = gptluna {
          timeout = 30;
        };

        # Prune and tend to my skills garden
        curator = gptluna {
          timeout = 600;
        };

        # Before session disappears, decide what should be remembered
        flush_memories = gptluna {
          timeout = 30;
        };

        # Kanban triage specifier
        triage_specifier = gptluna {
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
  xdg = lib.optionalAttrs config.desktop.enable {
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
