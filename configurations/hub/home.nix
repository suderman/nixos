{ config, lib, pkgs, ... }: {

  base.enable = true;
  secrets.enable = true;

  home.packages = with pkgs; [ 
    neofetch
    yo
  ];

  programs = {
    git.enable = true;
    tmux.enable = true;
    zsh.enable = true;
  };

}
