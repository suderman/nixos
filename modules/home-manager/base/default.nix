# base.enable = true;
{ config, lib, ... }: with lib; {

  # ---------------------------------------------------------------------------
  # Common configuration for all Home Manager hosts
  # ---------------------------------------------------------------------------
  options.base.enable = options.mkEnableOption "base"; 

  imports = [ 
    ./nix.nix 
    ./packages.nix 
    ./user.nix 
    ./wayland.nix 
    ./xdg.nix 
  ];

  config = mkIf config.base.enable {

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "22.05";

  };

}
