# This is your home-manager configuration file
{ inputs, outputs, host, lib, config, pkgs, ... }: {

  imports = [
    ../shared/tmux
  ];

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.packages = with pkgs; [ 
    bat 
    nnn 
    lf 
    fzf 
    sl
    # tmux
    nur.repos.mic92.hello-nur
    # neovim
  ];

  # programs.tmux.enable

  # home.file = { 
  #   ".emacs.d/init.el".source = config.lib.file.mkOutOfStoreSymlink ./init.el;
  #   ".emacs.d/early-init.el".source = config.lib.file.mkOutOfStoreSymlink ./early-init.el; 
  # };

  # home.file.".config/"
  # xdg.configFile."i3blocks/config".source = ./i3blocks.conf;
  # home.file.".gdbinit".text = ''
  #     set auto-load safe-path /nix/store
  # '';
}
