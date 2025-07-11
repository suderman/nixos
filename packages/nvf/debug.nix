{
  pkgs,
  flake,
  ...
}: let
  inherit (flake.lib) nmap tmap;
in {
  vim.lsp = {
    enable = true;
    formatOnSave = true;
    # lspkind.enable = true;
    lightbulb.enable = true;
    lightbulb.setupOpts.sign.text = "💡";
    trouble.enable = true;
    # lspSignature.enable = true;
    # otter-nvim.enable = false;
    nvim-docs-view.enable = true;

    # lspsaga = {
    #   enable = true;
    #   setupOpts = {
    #     lightbulb.virtual_text = false;
    #     code_action.keys.quit = "<Esc>";
    #   };
    # };
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
    enable = true;
    navbuddy.enable = true;
  };

  vim.keymaps = [
    (nmap "gC" ":TSContext toggle<CR>" "Toggle treesitter conte[x]t")
    (nmap "ga" "vim.lsp.buf.code_action" "Code Actions")
    (nmap "gl" "vim.diagnostic.open_float" "Error, Warnings, Hints")
    (nmap "gh" "vim.lsp.buf.hover" "LSP Hover")

    (nmap "<leader>xx" "<cmd>Trouble diagnostics toggle<cr>" "Diagnostics (Trouble)")
    (nmap "<leader>xb" "<cmd>Trouble diagnostics toggle filter.buf=0<cr>" "Buffer Diagnostics (Trouble)")
    (nmap "<leader>cs" "<cmd>Trouble symbols toggle focus=false<cr>" "Symbols (Trouble)")
    (nmap "<leader>cl" "<cmd>Trouble lsp toggle focus=false win.position=right<cr>" "LSP Definitions / references / ... (Trouble)")
    (nmap "<leader>xl" "<cmd>Trouble loclist toggle<cr>" "Location List (Trouble)")
    (nmap "<leader>xq" "<cmd>Trouble qflist toggle<cr>" "Quickfix List (Trouble)")

    # (nmap "gB" ":Lspsaga winbar_toggle<CR>" "LSP [b]readcrumb toggle")
    # (nmap "go" ":Lspsaga outline<CR>" "LSP [o]utline toggle")
    # (nmap "ga" ":Lspsaga code_action<CR>" "Code [a]ction")
    # (nmap "]d" ":Lspsaga diagnostic_jump_next<CR>" "Next diagnostic")
    # (nmap "[d" ":Lspsaga diagnostic_jump_prev<CR>" "Prev diagnostic")
    # (nmap "gl" ":Lspsaga show_line_diagnostics<CR>" "Show [l]ine diagnostic")
    # (nmap "gb" ":Lspsaga show_buf_diagnostics<CR>" "Show [b]uffer diagnostic")
    # (nmap "gh" ":Lspsaga hover_doc<CR>" "Show [h]over documentation")
    # (nmap "<M-/>" ":Lspsaga term_toggle<CR>" "Toggle terminal")
    # (tmap "<M-/>" ":Lspsaga term_toggle<CR>" "Toggle terminal")
  ];

  # Better Quickfix
  vim.lazy.plugins.nvim-bqf = {
    package = pkgs.vimPlugins.nvim-bqf;
  };
  vim.luaConfigRC.nvim-bqf = ''
    require('bqf').setup{}
  '';
}
