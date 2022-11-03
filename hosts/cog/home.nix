# This is your home-manager configuration file
{ inputs, outputs, hostname, lib, config, pkgs, ... }: {
  imports = [
    # ../shared/home.nix
  ];

  # TODO: Set your username
  home = {
    username = "me";
    homeDirectory = "/home/me";
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.packages = with pkgs; [ 
    sl
    nnn 
    owncloud-client
    _1password-gui
    nur.repos.mic92.hello-nur
    # neovim
  ];


  # home.file = { 
  #   ".emacs.d/init.el".source = config.lib.file.mkOutOfStoreSymlink ./init.el;
  #   ".emacs.d/early-init.el".source = config.lib.file.mkOutOfStoreSymlink ./early-init.el; 
  # };
  xdg.configFile."btop/btop.conf".source = ../../config/btop/btop.conf;
  xdg.configFile."hostname.txt".text = "The hostname is ${hostname}";

  # home.file.".config/"
  # xdg.configFile."i3blocks/config".source = ./i3blocks.conf;
  # home.file.".gdbinit".text = ''
  #     set auto-load safe-path /nix/store
  # '';

}
