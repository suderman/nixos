# modules.sunshine.enable = true;
{ config, lib, pkgs, this, ... }: 

let 

  cfg = config.modules.sunshine;
  inherit (lib) mkIf mkOption types;
  inherit (this.lib) ls;
  
in {

  imports = ls ./.;

  options = {
    modules.sunshine.enable = lib.options.mkEnableOption "sunshine"; 
  };

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      package = pkgs.unstable.sunshine;
      openFirewall = true;
      capSysAdmin = true;
    };
  };

}
