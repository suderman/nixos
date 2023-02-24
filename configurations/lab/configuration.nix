{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
  ];

  base.enable = true;
  state.enable = true;
  secrets.enable = true;

  # Configure the SSH daemon
  services.openssh.enable = true;

  # Other goodies
  services.keyd.enable = true;
  programs.neovim.enable = true;
  programs.mosh.enable = true;

}
