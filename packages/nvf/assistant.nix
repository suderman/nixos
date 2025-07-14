{
  lib,
  pkgs,
  perSystem,
  flake,
  ...
}: let
  inherit (flake.lib) mkLuaInline;
  ollamaUrl = "http://10.1.0.6:11434";
  ollamaModel = "qwen3:30b-a3b";
in {
  vim.assistant.codecompanion-nvim = {
    enable = true;
    setupOpts = {
      strategies = {
        chat.adapter = "ollama";
        inline.adapter = "ollama";
        cmd.adapter = "ollama";
      };
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
      adapters =
        mkLuaInline
        # lua
        ''
          {
            opts = {
              show_defaults = false,
            },
            ollama = function()
              return require("codecompanion.adapters").extend("ollama", {
                env = { url = "${ollamaUrl}", },
                headers = { ["Content-Type"] = "application/json", },
                parameters = { sync = true, },
                schema = {
                  model = { default = "${ollamaModel}", },
                  temperature = { default = 0.6, },
                  top_p = { default = 0.95, },
                  top_k = { default = 20, },
                  min_p = { default = 0, },
                },
              })
            end,
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

  # Add mcphub to lualine
  vim.statusline.lualine.extraActiveSection.x = [
    "require('mcphub.extensions.lualine')"
  ];
}
