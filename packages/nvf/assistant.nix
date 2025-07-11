{
  lib,
  pkgs,
  perSystem,
  flake,
  ...
}: let
  inherit (lib) mkForce;
  inherit (flake.lib) mkLuaInline;
in {
  vim.assistant.avante-nvim = {
    enable = true;
    setupOpts = {
      provider = "ollama";
      providers.ollama = {
        endpoint = "http://10.1.0.6:11434";
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
      dual_boost = {
        enabled = false;
        first_provider = "ollama";
        prompt = ''
          Based on the two reference outputs below, generate a response that incorporates
          elements from both but reflects your own judgment and unique perspective.
          Do not provide any explanation, just give the response directly. Reference Output 1:
          [{{provider1_output}}], Reference Output 2: [{{provider2_output}}
        '';
      };
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

  vim.luaConfigRC."avante.nvim" =
    # lua
    ''
      require("transparent").clear_prefix("Avante");
      require('transparent').toggle(true);
    '';

  vim.lazy.plugins = {
    "avante.nvim".package = mkForce perSystem.nixpkgs-unstable.vimPlugins.avante-nvim;
    "mcphub.nvim".package = perSystem.mcphub-nvim.default;
  };

  # https://ravitemer.github.io/mcphub.nvim/extensions/avante.html
  vim.luaConfigRC."mcphub.nvim" =
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
    "Avante"
  ];

  # https://github.com/Kaiser-Yang/blink-cmp-avante
  vim.autocomplete.blink-cmp.sourcePlugins = {
    blink-cmp-avante = {
      enable = true;
      package = perSystem.nixpkgs-unstable.vimPlugins.blink-cmp-avante;
      module = "blink-cmp-avante";
    };
  };

  # Add mcphub to lualine
  vim.statusline.lualine.extraActiveSection.x = [
    "require('mcphub.extensions.lualine')"
  ];
}
