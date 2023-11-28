{ config, lib, pkgs, _, ... }:

let

  cfg = config._;
  inherit (lib) mkIf mkOption optionalAttrs recursiveUpdate types;

in {

  imports = [ 
    ./packages.nix 
    ./user.nix 
  ];

  # Define underscore options
  options._ = mkOption { type = types.attrs; default = _; };

  # ---------------------------------------------------------------------------
  # Common Configuration for all Home Manager users
  # ---------------------------------------------------------------------------
  config = {

    # Get all modules settings from configuration's default.nix
    modules = optionalAttrs (_ ? modules) (recursiveUpdate _.modules {});

    # Set username and home directory
    home.username = _.user;
    home.homeDirectory = "/${if (pkgs.stdenv.isLinux) then "home" else "Users"}/${_.user}";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "22.05";

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch";

    # Enable flakes
    xdg.configFile = {
      "nix/nix.conf".text = "experimental-features = nix-command flakes";
    };

  };

}
