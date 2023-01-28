{ config, lib, pkgs, ... }: {

  # ---------------------------------------------------------------------------
  # User Environment & Packages
  # ---------------------------------------------------------------------------

  home.packages = with pkgs; [ 
    bat 
    cowsay
    exa
    killall
    lf 
    lsd
    micro
    mosh
    nano
    ripgrep
    wget
    python39
    python39Packages.pip
    python39Packages.virtualenv
    nodejs
    cargo
  ];

  # Enable home-manager, git & zsh
  programs = {
    home-manager.enable = true;
    git.enable = true;
    zsh.enable = true;
    fzf.enable = true;
    neovim.enable = true;
  };

}
