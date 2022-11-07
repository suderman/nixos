{ pkgs, ... }: {

  imports = [
    ./git.nix
    ./tmux.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [ 
    bat 
    lf 
    lsd
    exa
    fzf 
    wget
    git
    zsh
    fish
    nano
    micro
    killall
  ];

}
