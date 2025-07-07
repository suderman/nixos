{ lib', ... }: let
  inherit (lib') nmap tmap;
in { 

  vim.languages = {
    enableFormat = true; 
    enableTreesitter = true;
    enableExtraDiagnostics = true;

    nix = {
      enable = true;
      format.enable = true;
      format.type = "alejandra"; # nixfmt
    };
    markdown.enable = true;

    bash.enable = true;
    clang.enable = true;
    # css.enable = true;
    html.enable = true;
    sql.enable = true;
    java.enable = false;
    kotlin.enable = false;
    # ts.enable = true;
    go.enable = true;
    lua.enable = true;
    zig.enable = false;
    python.enable = true;
    typst.enable = false;
    rust = {
      enable = true;
      crates.enable = true;
    };

    assembly.enable = false;
    astro.enable = false;
    nu.enable = false;
    csharp.enable = false;
    julia.enable = false;
    vala.enable = false;
    scala.enable = false;
    r.enable = false;
    gleam.enable = false;
    dart.enable = false;
    ocaml.enable = false;
    elixir.enable = false;
    haskell.enable = false;
    ruby.enable = true;
    fsharp.enable = false;

    tailwind.enable = true;
    # svelte.enable = true;

    php = {
      enable = true;
      lsp.enable = true;
      treesitter.enable = true;
    };
    # python = {
    #   enable = true;
    #   lsp.enable = true;
    #   format.enable = true;
    #   format.type = "ruff";
    #   treesitter.enable = true;
    # };
  };

  vim.lsp = {
    enable = true;
    formatOnSave = true;
    lspkind.enable = true;
    lightbulb.enable = false;
    trouble.enable = false;
    lspSignature.enable = false;
    otter-nvim.enable = false;
    nvim-docs-view.enable = false;
    lspsaga = {
      enable = true;
      setupOpts = {
        lightbulb.virtual_text = false;
        code_action.keys.quit = "<Esc>";
      };
    };
  };

  vim.autocomplete.blink-cmp = {
    enable = true;
    friendly-snippets.enable = true;
    sourcePlugins = {
      emoji.enable = true;
      ripgrep.enable = true;
      spell.enable = true;
    };
    mappings = {
      close = "<C-e>";
      complete = "<C-n>";
      confirm = "<CR>";
      next = "<Tab>";
      previous = "<S-Tab>";
      scrollDocsDown = "<C-f>";
      scrollDocsUp = "<C-d>";
    };
  };

  vim.treesitter.context = {
    enable = true;
    setupOpts = {
      enable = false; # hide by default, toggle with gx
      max_lines = 0;
      separator = null;
    };
  };

  vim.keymaps = [
    (nmap "gC" ":TSContext toggle<CR>" "Toggle treesitter conte[x]t")
    (nmap "gB" ":Lspsaga winbar_toggle<CR>" "LSP [b]readcrumb toggle")
    (nmap "go" ":Lspsaga outline<CR>" "LSP [o]utline toggle")
    (nmap "ga" ":Lspsaga code_action<CR>" "Code [a]ction")
    (nmap "]d" ":Lspsaga diagnostic_jump_next<CR>" "Next diagnostic")
    (nmap "[d" ":Lspsaga diagnostic_jump_prev<CR>" "Prev diagnostic")
    (nmap "gl" ":Lspsaga show_line_diagnostics<CR>" "Show [l]ine diagnostic")
    (nmap "gb" ":Lspsaga show_buf_diagnostics<CR>" "Show [b]uffer diagnostic")
    (nmap "gh" ":Lspsaga hover_doc<CR>" "Show [h]over documentation")

    (nmap "<M-/>" ":Lspsaga term_toggle<CR>" "Toggle terminal")
    (tmap "<M-/>" ":Lspsaga term_toggle<CR>" "Toggle terminal")
    
  ];

  vim.ui.breadcrumbs = {
    enable = false;
    navbuddy.enable = true;
  };

}
