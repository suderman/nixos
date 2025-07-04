{ pkgs, lib, ... }: { 

  vim.assistant.codecompanion-nvim = {
    enable = true;
  };

  vim.assistant.goose = {
    enable = true;
  };

}
