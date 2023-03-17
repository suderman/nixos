{ config, lib, pkgs, ... }: {

  base.enable = true;
  secrets.enable = true;

  home.packages = with pkgs; [ 
    neofetch
    yo
  ];

  programs = {
    # neovim.enable = true;
    chromium.enable = true;
    git.enable = true;
    tmux.enable = true;
    wezterm.enable = true;
    kitty.enable = true;
    zsh.enable = true;
    dconf.enable = true;
  };

}
