{ config, lib, pkgs, ... }: {

  # Keyboard control
  services.keyd.enable = true;

  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  # File sync
  services.ocis.enable = true;

}
