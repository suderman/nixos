# base.enable = true;
{ config, lib, ... }: with lib; {

  # ---------------------------------------------------------------------------
  # Nix Settings
  # ---------------------------------------------------------------------------
  config = mkIf config.base.enable {

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch";

    # Enable flakes
    xdg.configFile = {
      "nix/nix.conf".text = "experimental-features = nix-command flakes";
    };

  };

}
