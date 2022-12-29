{ pkgs, ... }: {

  home.packages = with pkgs; [ 
    bat 
    lf 
    lsd
    exa
    fzf 
    wget
    zsh
    fish
    nano
    micro
    killall
    mosh
    cowsay
    inkscape
    nsxiv
    darktable
  ];

}
