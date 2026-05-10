{
  pkgs,
  perSystem,
  ...
}: {
  home = {
    # Personal neovim configuration
    packages = [perSystem.neovim.default];

    sessionVariables.EDITOR = "nvim";

    shellAliases = {
      v = "nvim";
      vi = "nvim";
      vim = "nvim";
      vimdiff = "nvim -d";
      diff = "nvim -d";
      nvim_ = "${pkgs.neovim}/bin/nvim"; # access to classic neovim
      vim_ = "${pkgs.vim}/bin/vim"; # access to classic vim
    };
  };
}
