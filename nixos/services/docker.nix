{ config, lib, pkgs, ... }:

let
  cfg = config.virtualisation.docker;

in {

  # virtualization.docker.enable = true;
  virtualisation.docker = {
    storageDriver = "overlay2";
  };

  persist.dirs = lib.mkIf cfg.enable [ "/var/lib/docker" ];

}
