{ config, lib, pkgs, ... }: {

  modules.base.enable = true;
  modules.secrets.enable = true;

  home.packages = with pkgs; [ 
    neofetch
    yo
    # unstable.yazi
  ];

  modules.yazi.enable = true;

  programs = {
    git.enable = true;
    tmux.enable = true;
    zsh.enable = true;
  };

}
