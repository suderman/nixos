{ pkgs, lib, ... }: { 

  vim.clipboard = {
    enable = true;
    providers.xclip.enable = true;
    providers.wl-copy.enable = true;
    registers = "unnamed";
  };

}
