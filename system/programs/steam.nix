{ config, lib, pkgs, ... }: 

let
  cfg = config.programs.steam;

in {

  # programs.steam.enable = true;

  programs.steam.remotePlay.openFirewall = lib.mkIf cfg.enable true;
  hardware.steam-hardware.enable = lib.mkIf cfg.enable true;

}
