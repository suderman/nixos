{flake, ...}: let
  inherit (flake.lib) imap mkLuaInline;
in {
  vim.autocomplete.blink-cmp = {
    enable = true;
    friendly-snippets.enable = true;
    sourcePlugins = {
      emoji.enable = true;
      ripgrep.enable = true;
      spell.enable = true;
      # blink-cmp-avante = {
      #   enable = true;
      #   package = pkgs.vimPlugins.blink-cmp-avante;
      #   module = "blink-cmp-avante";
      # };
    };
    mappings = {
      close = "<C-h>";
      complete = "<C-space>";
      # confirm = "<C-l>";
      confirm = "<Tab>";
      next = "<C-j>";
      previous = "<C-k>";
      scrollDocsDown = "<C-d>";
      scrollDocsUp = "<C-u>";
    };
    setupOpts = {
      sources.default = ["lsp" "path" "snippets" "buffer"];
      keymap.preset = "none";
      completion.ghost_text.enabled = true;
      completion.menu.auto_show = false;
      cmdline.completion.menu.auto_show =
        mkLuaInline
        # lua
        ''
          function(ctx)
            return vim.fn.getcmdtype() == ':'
          end
        '';
      # completion.menu.draw.columns = [
      #   { "@1" = "label"; "@2" = "label_description"; gap = 1; }
      #   [ "kind_icon" "kind" ]
      # ];
      # completion.menu.border = "rounded";
      # completion.documentation.window.border = "rounded";
      signature.enabled = true;
      signature.window.border = "rounded";
    };
  };
  vim.options.completeopt = "menu,noselect"; # customize completions
  vim.options.omnifunc = "";

  # Ctrl-l inserts spaces to match Ctrl-h backspace (built-in behaviour)
  vim.keymaps = [
    (imap "<C-l>" "<Space>" "Insert space")
  ];
}
