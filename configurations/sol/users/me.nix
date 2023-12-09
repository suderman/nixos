{ config, lib, pkgs, ... }: {

  # ---------------------------------------------------------------------------
  # Home Enviroment & Packages
  # ---------------------------------------------------------------------------

  home.packages = with pkgs; [ 
    owofetch
    neofetch
    unstable.nnn 
    unstable.sl
    yo
  ];

  programs = {
    # neovim.enable = true;
    git.enable = true;
    tmux.enable = true;
    zsh.enable = true;
  };

}
