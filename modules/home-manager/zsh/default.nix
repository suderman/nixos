# programs.zsh.enable = true;
{ config, lib, pkgs, ... }:

let 
  cfg = config.programs.zsh;

in {

  config = lib.mkIf cfg.enable {

    programs.zsh = {
      autocd = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      defaultKeymap = "viins"; # emacs, vicmd, or viins

      history = {
        expireDuplicatesFirst = true;
        extended = true;
        ignoreDups = true;
        ignorePatterns = [ ];
        ignoreSpace = false;
        save = 10000;
        share = true;
        size = 10000;
      };

      shellAliases = {
        switch = "echo nixos-rebuild switch --flake /etc/nixos#$(hostname) && sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)";
      };

      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
      };

      # initExtra = ''
      #   # zsh-fzf-tab
      #   . ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      # '';

    };

    home.packages = [ pkgs.zsh-fzf-tab ];

  };

}
