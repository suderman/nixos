# This is your home-manager configuration file
{ inputs, outputs, host, lib, config, pkgs, ... }: {

  imports = [
    ../../home
    ../../home/tmux
    ../../home/git.nix
    ../../home/wayland.nix
    ../../home/zsh.nix
    ../../home/xdg.nix
  ];

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.packages = with pkgs; [ 
    sl
    nnn 
    owncloud-client
    _1password-gui
    _1password
    nur.repos.mic92.hello-nur
    owofetch
    firefox
    # neovim
  ];


  # home.file = { 
  #   ".emacs.d/init.el".source = config.lib.file.mkOutOfStoreSymlink ./init.el;
  #   ".emacs.d/early-init.el".source = config.lib.file.mkOutOfStoreSymlink ./early-init.el; 
  # };
  # xdg.configFile."btop/btop.conf".source = ../../config/btop/btop.conf;
  # xdg.configFile."hostname.txt".text = "The hostname is ${host.hostname}";

  # home.file.".config/"
  # xdg.configFile."i3blocks/config".source = ./i3blocks.conf;
  # home.file.".gdbinit".text = ''
  #     set auto-load safe-path /nix/store
  # '';

}
