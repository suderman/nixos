{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix 
    ../shared/system 
  ];

  # Enable linode config
  linode.enable = true;

  # Configure the SSH daemon
  services.openssh.enable = true;

  # Other goodies
  services.keyd.enable = true;
  programs.neovim.enable = true;
  programs.mosh.enable = true;

}
