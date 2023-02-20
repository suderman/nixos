{ config, lib, pkgs, ... }: 

let
  cfg = config.programs.steam;

in {

  # programs.steam.enable = true;
  config = lib.mkIf cfg.enable {

    programs.steam.remotePlay.openFirewall = true;
    hardware.steam-hardware.enable = true;

  };

}
