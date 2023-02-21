{ config, lib, pkgs, ... }: {

  # ---------------------------------------------------------------------------
  # Common configuration for all Home Manager hosts
  # ---------------------------------------------------------------------------
  imports = [ 
    ./nix.nix 
    ./packages.nix 
    ./user.nix 
    ./wayland.nix 
    ./xdg.nix 
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.05";

}
