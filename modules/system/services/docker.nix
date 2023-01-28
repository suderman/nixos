{ config, lib, pkgs, ... }:

let
  cfg = config.virtualisation.docker;

in {

  # virtualization.docker.enable = true;
  virtualisation.docker = {
    storageDriver = "overlay2";
  };

}
