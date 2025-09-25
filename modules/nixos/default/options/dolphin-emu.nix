{
  config,
  pkgs,
  lib,
  flake,
  ...
}: {
  # https://github.com/dolphin-emu/dolphin/blob/master/Data/51-usb-device.rules
  config = lib.mkIf (flake.lib.anyUser config (u: u.programs.dolphin-emu.enable)) {
    services.udev.packages = [pkgs.dolphin-emu];
  };
}
