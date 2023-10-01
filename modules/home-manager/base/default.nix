# modules.base.enable = true;
{ config, lib, base, ... }:

let

  cfg = config.modules.base;
  inherit (lib) mkIf optionalAttrs recursiveUpdate;

in {

  imports = [ 
    ./nix.nix 
    ./packages.nix 
    ./user.nix 
    ./wayland.nix 
    ./xdg.nix 
  ];

  # ---------------------------------------------------------------------------
  # Common Configuration for all NixOS hosts
  # ---------------------------------------------------------------------------
  options.modules.base = {
    enable = lib.options.mkEnableOption "base"; 
  };

  config = mkIf cfg.enable {

    # Get all modules settings from configuration's default.nix
    modules = optionalAttrs (base ? modules) (recursiveUpdate base.modules {});

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "22.05";

  };

}
