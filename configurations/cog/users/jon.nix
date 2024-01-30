{ config, lib, pkgs, ... }: {

  home.packages = with pkgs; [ bat ];

  programs = {
    chromium.enable = true;
    git.enable = true;
    tmux.enable = true;
    zsh.enable = true;
  };

  # terminal du jour
  modules.kitty.enable = true;
  # modules.firefox.enable = true;

}
