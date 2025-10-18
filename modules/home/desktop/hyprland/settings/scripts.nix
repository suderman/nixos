{
  lib,
  pkgs,
  perSystem,
  ...
}: let
  scripts = with builtins;
    attrNames (
      lib.filterAttrs
      (n: v: v == "regular" && lib.hasSuffix ".sh" n)
      (readDir ../scripts)
    );

  path = with pkgs; [
    coreutils
    gawk
    gnugrep
    gnused
    hyprpicker
    jq
    libnotify
    socat
    wl-clipboard
  ];
in {
  home.packages =
    map (name: (
      perSystem.self.mkScript {
        inherit path;
        name = lib.removeSuffix ".sh" name;
        text = ../scripts/${name};
      }
    ))
    scripts;
}
