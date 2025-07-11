{
  flake,
  perSystem,
  ...
}: let
  inherit (flake.lib) mkLuaInline;
  mcp-hub = perSystem.mcp-hub.default; # server binary
  mcphub-nvim = perSystem.mcphub-nvim.default; # neovim plugin
in {
  vim.assistant.avante-nvim = {
    enable = true;
    setupOpts = {
      provider = "ollama";
      providers.ollama = {
        endpoint = "http://10.1.0.6:11434";
        # model =  "qwen2.5:14b";
        model = "qwen3:8b";
        timeout = 30000; # Timeout in milliseconds
        extra_request_body.options = {
          temperature = 0.75;
          num_ctx = 20480;
          keep_alive = "5m";
        };
      };
      behaviour.enable_token_counting = true;
      auto_suggestions_provider = "ollama";
      dual_boost.enabled = false;
      dual_boost.first_provider = "ollama";
      dual_boost.prompt = ''
        Based on the two reference outputs below, generate a response that incorporates
        elements from both but reflects your own judgment and unique perspective.
        Do not provide any explanation, just give the response directly. Reference Output 1:
        [{{provider1_output}}], Reference Output 2: [{{provider2_output}}
      '';
      system_prompt =
        mkLuaInline
        # lua
        ''
          function()
            local hub = require("mcphub").get_hub_instance()
            return hub and hub:get_active_servers_prompt() or ""
          end
        '';
      custom_tools =
        mkLuaInline
        # lua
        ''
          function()
            return {
              require("mcphub.extensions.avante").mcp_tool(),
            }
          end
        '';
      disabled_tools = [
        "list_files" # Built-in file operations
        "search_files"
        "read_file"
        "create_file"
        "rename_file"
        "delete_file"
        "create_dir"
        "rename_dir"
        "delete_dir"
        "bash" # Built-in terminal access
      ];
    };
  };

  # https://ravitemer.github.io/mcphub.nvim/extensions/avante.html
  vim.luaConfigRC."mcphub.nvim" =
    # lua
    ''
      require('mcphub').setup {
        cmd = "${mcp-hub}/bin/mcp-hub",
        auto_approve = true,
        extensions = {
          avante = {
            make_slash_commands = true, -- make /slash commands from MCP server prompts
          }
        }
      }
    '';

  # vim.extraPackages = [perSystem.mcphub-nvim.default];

  vim.lazy.plugins."mcphub.nvim" = {
    package = mcphub-nvim;
  };

  vim.languages.markdown.extensions.render-markdown-nvim.setupOpts.file_types = [
    "codecompanion"
    "Avante"
  ];

  # vim.assistant.codecompanion-nvim = {
  #   enable = false;
  #   setupOpts = {
  #     adapters =
  #       mkLuaInline
  #       # lua
  #       ''
  #         {
  #           deepseek = function()
  #             return require("codecompanion.adapters").extend("deepseek", {
  #               env = {
  #                 api_key = "cmd: cat ~/.config/nvf/deepseek_apikey",
  #               },
  #             })
  #           end,
  #
  #           ollama = function()
  #             return require("codecompanion.adapters").extend("ollama", {
  #               env = {
  #                 url = "http://localhost:11434",
  #                 api_key = "123",
  #               },
  #               headers = {
  #                 ["Content-Type"] = "application/json",
  #                 ["Authorization"] = "Bearer 123",
  #               },
  #               parameters = {
  #                 sync = true,
  #               },
  #             })
  #           end,
  #         }
  #       '';
  #
  #     strategies = {
  #       chat.adapter = "copilot";
  #       inline.adapter = "copilot";
  #     };
  #     display.chat = {
  #       auto_scroll = true;
  #       show_settings = true;
  #     };
  #   };
  # };
}
