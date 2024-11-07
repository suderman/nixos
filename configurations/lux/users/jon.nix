{ config, lib, pkgs, ... }: {

  home.packages = with pkgs; [ 
    neofetch
    yo
    lazygit
    lazydocker
    parted
    imagemagick
    yt-dlp
  ];

  programs = {
    git.enable = true;
    tmux.enable = true;
    zsh.enable = true;
    yazi.enable = true;
  };

  # Music daemon
  services.mpd = {
    enable = true;
    musicDirectory = "/media/music";
  };
}
