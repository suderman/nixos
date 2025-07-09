{ ... }: { 

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
      close = "<Esc>";
      complete = "<C-Space>";
      confirm = "<CR>";
      next = "<C-n>";
      previous = "<C-p>";
      scrollDocsDown = "<C-d>";
      scrollDocsUp = "<C-u>";
    };
    setupOpts = {
      completion.menu.border = "rounded";
      completion.documentation.window.border = "rounded";
      signature.enabled = true;
      signature.window.border = "rounded";
    };
  };
  vim.options.completeopt = "menu,noselect"; # customize completions
  vim.options.omnifunc = "";

}
