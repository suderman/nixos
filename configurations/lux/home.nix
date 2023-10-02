{ config, lib, pkgs, ... }: {

  modules.base.enable = true;
  modules.secrets.enable = true;

  home.packages = with pkgs; [ 
    neofetch
    yo

    lazygit
    lazydocker
    parted
    imagemagick
    yt-dlp

  ];

  modules.yazi.enable = true;

  programs = {
    git.enable = true;
    tmux.enable = true;
    zsh.enable = true;
  };

}
