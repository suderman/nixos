{ config, lib, pkgs, ... }: {

  # Keyboard control
  services.keyd.enable = true;

  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  # File sync
  services.ocis.enable = true;
  services.syncthing.enable = true;

  # Sync health data
  services.withings-sync.enable = true;

  # Music daemon
  services.mpd = {
    enable = true;
    # musicDirectory = "/media/music";
    # proxy = "lux";
  };

}
