{flake, ...}: let
  inherit (flake.lib) mkLuaInline;
in {
  vim.languages.markdown.extensions.render-markdown-nvim.setupOpts.file_types = [
    "codecompanion"
    "Avante"
  ];

  vim.assistant.codecompanion-nvim = {
    enable = true;
    setupOpts = {
      adapters =
        mkLuaInline
        # lua
        ''
          {
            deepseek = function()
              return require("codecompanion.adapters").extend("deepseek", {
                env = {
                  api_key = "cmd: cat ~/.config/nvf/deepseek_apikey",
                },
              })
            end,

            ollama = function()
              return require("codecompanion.adapters").extend("ollama", {
                env = {
                  url = "http://localhost:11434",
                  api_key = "123",
                },
                headers = {
                  ["Content-Type"] = "application/json",
                  ["Authorization"] = "Bearer 123",
                },
                parameters = {
                  sync = true,
                },
              })
            end,
          }
        '';

      strategies = {
        chat.adapter = "copilot";
        inline.adapter = "copilot";
      };
      display.chat = {
        auto_scroll = true;
        show_settings = true;
      };
    };
  };
}
