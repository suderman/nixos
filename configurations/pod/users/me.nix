{ config, lib, pkgs, ... }: {

  home.packages = with pkgs; [ 
    neofetch
    yo
    firefox-wayland
    zwift 
  ];

  programs = {
    git.enable = true;
    tmux.enable = true;
    zsh.enable = true;
  };

}
