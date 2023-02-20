{ config, lib, pkgs, ... }: {

  # ---------------------------------------------------------------------------
  # User Environment & Packages
  # ---------------------------------------------------------------------------

  home.packages = with pkgs; [ 
    bat 
    cargo
    cowsay
    exa
    killall
    lf 
    lsd
    micro
    mosh
    nano
    nodejs
    python39
    python39Packages.pip
    python39Packages.virtualenv
    ripgrep
    sysz
    tealdeer
    wget

    darktable
    fish
    inkscape
    nsxiv
    zsh

  ];

  # Enable home-manager, git & zsh
  programs = {
    home-manager.enable = true;
    git.enable = true;
    zsh.enable = true;
    fzf.enable = true;
    neovim.enable = true;
    direnv.enable = true;
    direnv.nix-direnv.enable = true;
  };

}
