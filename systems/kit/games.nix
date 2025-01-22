{ config, pkgs, lib, ... }: {

  programs.dolphin.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; 
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

}
