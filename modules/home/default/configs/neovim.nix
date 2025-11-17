{pkgs, ...}: {
  home = {
    packages = [
      # Personal neovim configuration
      # https://github.com/NotAShelf/nvf
      pkgs.nvf

      # Also create wrapper for nvf with expected name nvim
      (pkgs.self.mkScript {
        name = "nvim";
        text = ''exec ${pkgs.nvf}/bin/nvf "$@"'';
      })
    ];

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
