# virtualization.docker.enable = true;
{ config, lib, pkgs, ... }:

let
  cfg = config.virtualisation.docker;

in {

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      storageDriver = "overlay2";
    };
  };

}
