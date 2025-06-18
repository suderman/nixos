{ config, pkgs, lib, ... }: {

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; 
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

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
}
