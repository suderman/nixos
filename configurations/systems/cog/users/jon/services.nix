{ config, lib, pkgs, this, ... }: {

  # Keyboard control
  services.keyd.enable = true;

  # File sync
  services.syncthing.enable = true;

  # Music daemon
  services.mpd.enable = true;

}
