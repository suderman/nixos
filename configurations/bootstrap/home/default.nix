{ config, lib, this, ... }:

let

  inherit (lib) optionalAttrs recursiveUpdate;

in {

  # ---------------------------------------------------------------------------
  # Common Configuration for all Home Manager users
  # (configurations/default.nix auto imports all .nix files in this directory)
  # ---------------------------------------------------------------------------
  # Inherit any config settings in configuration's default.nix
  config = optionalAttrs (this ? config) (recursiveUpdate this.config {

    # Set username and home directory
    home.username = this.user;
    home.homeDirectory = this.lib.homeDir;

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "22.05";

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch";

    # Enable flakes
    xdg.configFile = {
      "nix/nix.conf".text = "experimental-features = nix-command flakes";
    };

  });

}
