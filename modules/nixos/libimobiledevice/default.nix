# modules.libimobiledevice.enable = true;
{ config, lib, pkgs, ... }: 

let 

  cfg = config.modules.libimobiledevice;
  inherit (lib) mkIf;

in {

  options.modules.libimobiledevice = {
    enable = lib.options.mkEnableOption "libimobiledevice"; 
  };

  config = mkIf cfg.enable {
    services.usbmuxd.enable = true;
    environment.systemPackages = [ pkgs.libimobiledevice ];
  };

}


