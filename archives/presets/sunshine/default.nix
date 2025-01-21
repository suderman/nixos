# modules.sunshine.enable = true;
{ config, lib, pkgs, this, ... }: 

let 

  cfg = config.modules.sunshine;
  inherit (lib) mkIf mkOption types;
  inherit (this.lib) ls;
  
in {

  # imports = ls ./.;

  options = {
    modules.sunshine.enable = lib.options.mkEnableOption "sunshine"; 
  };

  # config = lib.mkIf cfg.enable {
  #   services.sunshine = {
  #     enable = true;
  #     package = pkgs.sunshine;
  #     openFirewall = true;
  #     capSysAdmin = true;
  #   };
  #   networking.firewall.allowedTCPPortRanges = [{ from = 47984; to = 48010; }];
  #   networking.firewall.allowedUDPPortRanges = [{ from = 47998; to = 48000; }];
  # };


}
