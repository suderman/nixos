{ config, lib, pkgs, ... }: {

  # Keyboard control
  services.keyd.enable = true;

  # File sync
  services.syncthing.enable = true;

  # Sync health data
  services.withings-sync.enable = true;

  # Music daemon
  services.mpd.enable = true;

  # Phone control
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

}
