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
      (readDir ./.)
    );

  path = with pkgs; [
    gawk
    jq
    libnotify
  ];
in {
  home.packages =
    map (name: (
      perSystem.self.mkScript {
        inherit path;
        name = lib.removeSuffix ".sh" name;
        text = ./${name};
      }
    ))
    scripts;
}
