{pkgs, ...}: {
  environment = {
    systemPackages = [pkgs.nvf];
    sessionVariables.EDITOR = "nvf";
    shellAliases = {
      v = "${pkgs.nvf}/bin/nvf";
      vi = "${pkgs.nvf}/bin/nvf";
      vim = "${pkgs.nvf}/bin/nvf";
      vimdiff = "${pkgs.nvf}/bin/nvf -d";
      diff = "${pkgs.nvf}/bin/nvf -d";
      nvim = "${pkgs.neovim}/bin/nvim"; # access to classic neovim
      vim9 = "${pkgs.vim}/bin/vim"; # access to classic vim
    };
  };
}
