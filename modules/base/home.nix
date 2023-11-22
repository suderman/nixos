{ config, lib, pkgs, base, ... }:

let

  cfg = config.modules.base;
  inherit (lib) mkIf mkOption optionalAttrs recursiveUpdate types;

in {

  imports = [ 
    ./home-packages.nix 
    ./home-user.nix 
  ];

  options.modules.base = {
    config = mkOption { type = types.attrs; default = base; };
  };

  # ---------------------------------------------------------------------------
  # Common Configuration for all Home Manager users
  # ---------------------------------------------------------------------------
  config = {

    # Get all modules settings from configuration's default.nix
    modules = optionalAttrs (base ? modules) (recursiveUpdate base.modules {});

    # Set username and home directory
    home.username = base.user;
    home.homeDirectory = "/${if (pkgs.stdenv.isLinux) then "home" else "Users"}/${base.user}";

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
