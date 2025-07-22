# perSystem.self.wrapWithFlags {}
{pkgs, ...}: {
  package ? pkgs.hello,
  flags ? [],
  name ? null,
}: let
  inherit (pkgs) lib makeWrapper symlinkJoin;
  inherit (lib) concatStringsSep getName;

  binName =
    if name != null
    then name
    else if package.meta ? mainProgram
    then package.meta.mainProgram
    else getName package;
in
  symlinkJoin {
    name = "${binName}-wrapped";
    paths = [package];
    buildInputs = [makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/${binName} \
        --add-flags "${concatStringsSep " " flags}"
    '';
  }
