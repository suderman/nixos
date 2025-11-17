{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.rofi;
  scripts = with builtins;
    attrNames (
      lib.filterAttrs
      (n: v: v == "regular" && lib.hasSuffix ".sh" n)
      (readDir ./.)
    );

  path = with pkgs; [
    bluez # bluetoothctl
    cliphist # clipboard
    gawk # awk
    gettext # envsubst
    gnugrep # grep
    gnused # sed
    jq
    procps # pidof kill
    pulseaudio # pactl
  ];
in {
  config = lib.mkIf cfg.enable {
    home.packages =
      map (name: (
        pkgs.self.mkScript {
          inherit path;
          name = lib.removeSuffix ".sh" name;
          text = ./${name};
        }
      ))
      scripts;
  };
}
