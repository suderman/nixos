{ pkgs, lib, ... }: { 

  vim.git.enable = true;
  vim.git.gitsigns.enable = true;
  vim.git.gitsigns.codeActions.enable = false; # throws an annoying debug message
  vim.utility.diffview-nvim.enable = true;

}
