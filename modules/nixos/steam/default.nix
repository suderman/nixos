# programs.steam.enable = true;
{ config, lib, pkgs, ... }: 

let
  cfg = config.programs.steam;

in {

  config = lib.mkIf cfg.enable {

    programs.steam.remotePlay.openFirewall = true;
    hardware.steam-hardware.enable = true;

  };

}
