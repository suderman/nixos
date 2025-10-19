{
  lib,
  pkgs,
  ...
}: let
  scripts = with builtins;
    attrNames (
      lib.filterAttrs
      (n: v: v == "regular" && lib.hasSuffix ".sh" n)
      (readDir ./.)
    );

  path = with pkgs; [
    coreutils
    gnused
    jq
    socat
  ];
in {
  home.packages =
    map (name: (
      pkgs.self.mkScript {
        inherit path;
        name = lib.removeSuffix ".sh" name;
        text = ./${name};
      }
    ))
    scripts;
}
