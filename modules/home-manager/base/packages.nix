# base.enable = true;
{ config, lib, pkgs, ... }: with lib; {

  # ---------------------------------------------------------------------------
  # User Environment & Packages
  # ---------------------------------------------------------------------------
  config = mkIf config.base.enable {

    home.packages = with pkgs; [ 
      bat 
      killall
      lf 
      ripgrep
      sysz
      tealdeer
      wget
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

  };

}
