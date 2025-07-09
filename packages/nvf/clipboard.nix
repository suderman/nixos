{ pkgs, lib, ... }: { 

  vim.clipboard = {
    enable = true;
    providers.xclip.enable = false;
    providers.wl-copy.enable = true;
    registers = "unnamedplus";
  };

}
