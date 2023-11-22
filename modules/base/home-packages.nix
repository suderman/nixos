{ config, pkgs, ... }: {

  # ---------------------------------------------------------------------------
  # User Environment & Packages
  # ---------------------------------------------------------------------------

  home.packages = with pkgs; [ 
    bat 
    killall
    lf 
    ripgrep
    sysz
    tealdeer
    wget
    lsd
  ];

  # Enable home-manager, git & zsh
  programs = {
    home-manager.enable = true;
    git.enable = true;
    zsh.enable = true;
    fzf.enable = true;
    neovim.enable = true;
    direnv.enable = true;
  };

}
