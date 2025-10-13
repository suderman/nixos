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
    jq
    socat
    wl-clipboard

    grim
    hyprpicker
    slurp
    swappy
    unstable.satty
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
