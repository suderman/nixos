{ config, lib, pkgs, ... }: {

  modules.base.enable = true;
  modules.secrets.enable = true;

  home.packages = with pkgs; [ 
    neofetch
    yo
    firefox-wayland
  ];

  programs = {
    git.enable = true;
    tmux.enable = true;
    zsh.enable = true;
  };

  # terminal du jour
  modules.kitty.enable = true;

}
