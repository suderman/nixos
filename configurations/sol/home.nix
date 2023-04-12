{ config, lib, pkgs, ... }: {

  modules.base.enable = true;
  modules.secrets.enable = false;

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
