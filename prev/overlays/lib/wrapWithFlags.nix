{ lib, pkgs, ... }:
  { package, flags, name ? null }: let

    inherit (lib) concatStringsSep getName;
    inherit (pkgs) makeWrapper symlinkJoin;

    binName =
      if name != null then name
      else if package.meta ? mainProgram then package.meta.mainProgram
      else getName package;

  in symlinkJoin {
    name = "${binName}-wrapped";
    paths = [ package ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/${binName} \
        --add-flags "${concatStringsSep " " flags}"
    '';
}
