# perSystem.self.wrapWithFlags {}
{pkgs, ...}: let
  inherit (pkgs) lib makeWrapper symlinkJoin;
  inherit (lib) concatStringsSep getName;
in rec {
  meta.isHelper = true;

  __functor = _:
    {
      package ? pkgs.hello,
      flags ? [],
      name ? null,
    }: let
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
      };
}
