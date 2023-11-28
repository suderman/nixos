{ config, lib, pkgs, this, ... }:

let

  cfg = config.this;
  inherit (lib) mkIf mkOption optionalAttrs recursiveUpdate types;

in {

  imports = [ 
    ./packages.nix 
    ./user.nix 
  ];

  # Define this options
  options.this = mkOption { type = types.attrs; default = this; };

  # ---------------------------------------------------------------------------
  # Common Configuration for all Home Manager users
  # ---------------------------------------------------------------------------
  # Get all modules settings from configuration's default.nix
  config = (optionalAttrs (this ? config) (recursiveUpdate this.config {})) // {

    # Set username and home directory
    home.username = this.user;
    home.homeDirectory = "/${if (pkgs.stdenv.isLinux) then "home" else "Users"}/${this.user}";

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
