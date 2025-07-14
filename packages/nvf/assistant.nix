{
  lib,
  pkgs,
  perSystem,
  flake,
  ...
}: let
  inherit (flake.lib) nmap vmap mkLuaInline;
in {
  vim.assistant.codecompanion-nvim = {
    enable = true;
    setupOpts = {
      display.chat = {
        auto_scroll = true;
        intro_message = "Welcome to CodeCompanion ✨! Press ? for options";
        show_header_separator = false; # Show header separators in the chat buffer?
        separator = "─"; # The separator between the different messages in the chat buffer
        show_references = true; # Show references (from slash commands and variables) in the chat buffer?
        show_settings = true; # Show LLM settings at the top of the chat buffer?
        show_token_count = true; # Show the token count for each response?
        start_in_insert_mode = false; # Open the chat buffer in insert mode?
      };
      display.action_palette = {
        width = 95;
        height = 10;
        prompt = "Prompt "; # Prompt used for interactive LLM calls
        provider = "default"; # snacks
        opts = {
          show_default_actions = true; # Show the default actions in the action palette?
          show_default_prompt_library = true; # Show the default prompt library in the action palette?
        };
      };
      strategies = {
        chat.adapter = "ollama";
        chat.slash_commands = mkLuaInline "{ opts = { provider = 'snacks' }, }";
        inline.adapter = "ollama";
        cmd.adapter = "ollama";
      };
      adapters = let
        ollama = {
          url = "http://10.1.0.6:11434";
          model = "qwen3:30b-a3b";
        };
        claude = {
          url = "https://openrouter.ai/api";
          model = "anthropic/claude-3.7-sonnet";
          api_key = "OPENROUTER_API_KEY";
        };
      in
        mkLuaInline
        # lua
        ''
          {
            ollama = function()
              return require("codecompanion.adapters").extend("ollama", {
                env = { url = "${ollama.url}", },
                headers = { ["Content-Type"] = "application/json", },
                parameters = { sync = true, },
                schema = {
                  model = { default = "${ollama.model}", },
                  temperature = { default = 0.6, },
                  top_p = { default = 0.95, },
                  top_k = { default = 20, },
                  min_p = { default = 0, },
                },
              })
            end,
            claude = function()
              return require("codecompanion.adapters").extend("openai_compatible", {
                env = {
                  url = "${claude.url}",
                  api_key = "${claude.api_key}",
                },
                schema = {
                  model = { default = "${claude.model}", },
                },
              })
            end,
            opts = {
              show_defaults = false,
            },
          }
        '';
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion";
          opts = {
            show_result_in_chat = true; #  Show mcp tool results in chat
            make_vars = true; #  Convert resources to #variables
            make_slash_commands = true; #  Add prompts as /slash commands
          };
        };
      };
    };
  };

  # Override plugin with latest from Github (via flake input)
  # and include dependency of mcphub-nvim
  vim.pluginOverrides.codecompanion-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "codecompanion-nvim";
    src = flake.inputs.codecompanion-nvim;
    version = "main";
    doCheck = false;
    dependencies = [perSystem.mcphub-nvim.default];
  };

  # https://ravitemer.github.io/mcphub.nvim/extensions/avante.html
  vim.luaConfigRC."mcphub.nvim" =
    lib.nvim.dag.entryBefore ["lazyConfigs"]
    # lua
    ''
      require('mcphub').setup {
        cmd = "${perSystem.mcp-hub.default}/bin/mcp-hub",
        auto_approve = true,
        extensions = {
          avante = {
            make_slash_commands = true, -- make /slash commands from MCP server prompts
          }
        }
      }
    '';

  # https://ravitemer.github.io/mcphub.nvim/other/troubleshooting.html#environment-requirements
  vim.extraPackages = with pkgs; [
    nodejs # npx
    python3
    uv # uvx
  ];

  vim.languages.markdown.extensions.render-markdown-nvim.setupOpts.file_types = [
    "codecompanion"
    # "Avante"
  ];

  vim.autocomplete.blink-cmp.setupOpts.sources.per_filetype = {
    codecompanion = ["codecompanion"];
  };

  # Add mcphub to lualine
  vim.statusline.lualine.extraActiveSection.x = [
    "require('mcphub.extensions.lualine')"
  ];

  vim.keymaps = [
    (nmap "<leader>ac" "<cmd>CodeCompanionChat<cr>" "CodeCompanion Chat")
    (nmap "<leader>at" "<cmd>CodeCompanionChat Toggle<cr>" "CodeCompanion Chat")
    (nmap "<C-a>" "<cmd>CodeCompanionChat Toggle<cr>" "Toggle CodeCompanion Chat")
    (nmap "<leader>aa" "<cmd>CodeCompanionActions<cr>" "CodeCompanion Actions")
    (vmap "<leader>ay" "<cmd>CodeCompanionChat Add<cr>" "Yank to chat")
  ];
}
