{ config, lib, pkgs, ... }: {

  imports = [ ../_/home ];

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
