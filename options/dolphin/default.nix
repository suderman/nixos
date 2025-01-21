# -- modified module --
# programs.dolphin.enable = true;
{ config, pkgs, lib, ... }: let

  cfg = config.programs.dolphin;
  inherit (lib) mkIf;

in {

  options.programs.dolphin = {
    enable = lib.options.mkEnableOption "dolphin"; 
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [ pkgs.dolphin-emu ];
    services.udev.packages = [ pkgs.dolphin-emu ];

    # https://github.com/dolphin-emu/dolphin/blob/master/Data/51-usb-device.rules
    services.udev.extraRules = lib.mkAfter ''
      
      # GameCube Controller Adapter
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", TAG+="uaccess"

      # Wiimotes or DolphinBar
      SUBSYSTEM=="hidraw*", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0306", TAG+="uaccess"
      SUBSYSTEM=="hidraw*", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0330", TAG+="uaccess"

    '';

  };

}
