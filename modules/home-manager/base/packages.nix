{ config, lib, pkgs, ... }:

let

  cfg = config.modules.base;
  inherit (lib) mkIf;

in {

  # ---------------------------------------------------------------------------
  # User Environment & Packages
  # ---------------------------------------------------------------------------
  config = mkIf cfg.enable {

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

  };

}
