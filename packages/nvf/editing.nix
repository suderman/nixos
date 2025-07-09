{ pkgs, lib, ... }: { 

  vim.searchCase = "smart"; # ignore, smart, sensitive
  vim.options.virtualedit = "block,insert,onemore"; # allow positioning cursor where no character exists
  vim.options.formatoptions = "qjl1"; # don't autoformat comments
  vim.options.listchars = "tab:> ,extends:…,precedes:…,nbsp:␣"; # define which helper symbols to show
  vim.options.list = true; # show some helper symbols

  vim.mini.ai.enable = true;
  vim.mini.align.enable = true;
  vim.mini.surround.enable = true;

  # indenting and tab behaviour
  vim.options.tabstop = 2; # number of visual spaces per tab
  vim.options.softtabstop = 2; # number of spaces when pressing tab in insert mode
  vim.options.expandtab = true; # tabs are spaces
  vim.options.shiftwidth = 2; # number of spaces to use for autoindent
  vim.options.wildmode = "list:longest,list:full";

  vim.utility.snacks-nvim.setupOpts.indent = {
    enabled = true;
    animate.duration.step = 10;
    animate.duration.total = 200;
    scope.enabled = true;
    scope.hl = "LineNr";
    scope.underline = true;
  };

  # navigate cursor with "s"
  vim.utility.motion.flash-nvim.enable = true; 

}
