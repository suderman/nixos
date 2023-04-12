{ config, lib, ... }:

let

  cfg = config.modules.base;
  inherit (lib) mkIf;

in {

  # ---------------------------------------------------------------------------
  # Nix Settings
  # ---------------------------------------------------------------------------
  config = mkIf cfg.enable {

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch";

    # Enable flakes
    xdg.configFile = {
      "nix/nix.conf".text = "experimental-features = nix-command flakes";
    };

  };

}
