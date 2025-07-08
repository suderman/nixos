{ lib', ... }: let
  inherit (lib') nmap tmap;
in { 

  vim.lsp = {
    enable = true;
    formatOnSave = true;
    # lspkind.enable = true;
    # lightbulb.enable = false;
    # trouble.enable = false;
    # lspSignature.enable = false;
    # otter-nvim.enable = false;
    # nvim-docs-view.enable = false;
    lspsaga = {
      enable = true;
      setupOpts = {
        lightbulb.virtual_text = false;
        code_action.keys.quit = "<Esc>";
      };
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

  vim.ui.breadcrumbs = {
    enable = false;
    navbuddy.enable = true;
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

}
