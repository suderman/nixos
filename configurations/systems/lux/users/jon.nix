{ config, lib, pkgs, ... }: {

  # Music daemon
  services.mpd = {
    enable = true;
    musicDirectory = "/media/music";
  };

}
