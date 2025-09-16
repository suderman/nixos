{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (builtins) attrNames any;
  inherit (lib) mkIf;
  # If any home-manager dolphin-emu is enabled for any user, set this to true
  users = config.home-manager.users or {};
  enable = any (user: users.${user}.programs.dolphin-emu.enable or false) (attrNames users);
in {
  config = mkIf enable {
    services.udev.packages = [pkgs.dolphin-emu];

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
