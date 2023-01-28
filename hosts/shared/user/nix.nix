{ inputs, config, lib, pkgs, ... }: {

  # ---------------------------------------------------------------------------
  # Nix Settings
  # ---------------------------------------------------------------------------

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Enable flakes
  xdg.configFile = {
    "nix/nix.conf".text = "experimental-features = nix-command flakes";
  };

}
