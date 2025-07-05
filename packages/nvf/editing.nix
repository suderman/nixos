{ pkgs, lib, ... }: { 

  vim.searchCase = "smart"; # ignore, smart, sensitive
  vim.options.completeopt = "menuone,noselect"; # customize completions
  vim.options.virtualedit = "block,insert,onemore"; # allow positioning cursor where no character exists
  vim.options.formatoptions = "qjl1"; # don't autoformat comments
  vim.options.listchars = "tab:> ,extends:…,precedes:…,nbsp:␣"; # define which helper symbols to show
  vim.options.list = true; # show some helper symbols

  vim.mini.ai.enable = true;
  vim.mini.align.enable = true;
  vim.mini.surround.enable = true;
  vim.autopairs.nvim-autopairs.enable = true;

}
