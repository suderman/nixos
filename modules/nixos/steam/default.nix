# modules.steam.enable = true;
{ config, lib, pkgs, ... }: 

let

  cfg = config.modules.steam;
  inherit (lib) mkIf mkOption types;

in {

  options.modules.steam = {
    enable = lib.options.mkEnableOption "steam"; 
  };

  config = mkIf cfg.enable {

    programs.steam.remotePlay.openFirewall = true;
    hardware.steam-hardware.enable = true;

  };

}
