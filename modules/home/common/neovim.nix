{pkgs, ...}: {
  # System nvim is wrapped nvf package
  home.sessionVariables = {
    EDITOR = "nvim";
  };
  home.shellAliases = {
    v = "nvim";
    vi = "nvim";
    vim = "nvim";
    vimdiff = "nvim -d";
    diff = "nvim -d";
    vim9 = "${pkgs.vim}/bin/vim"; # access to classic vim
  };
}
