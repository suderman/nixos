{ config, lib, this, ... }:

let

  inherit (lib) optionalAttrs recursiveUpdate;
  inherit (this.lib) ls;

in {

  # Import all *.nix files in this directory
  imports = ls ./.;

  # ---------------------------------------------------------------------------
  # Common Configuration for all Home Manager users
  # (configurations/default.nix auto imports all .nix files in this directory)
  # ---------------------------------------------------------------------------
  # Inherit any config settings in configuration's default.nix
  config = optionalAttrs (this ? config) (recursiveUpdate this.config {

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
