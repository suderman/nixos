# perSystem.self.enableWayland {}
{pkgs, ...}: let
  inherit (pkgs) lib makeWrapper symlinkJoin;
  inherit (lib) getName;
in rec {
  meta.isHelper = true;

  # Force package to run in Wayland
  # example:
  # owncloud-client = enableWayland { type = "qt"; pkg = pkgs.owncloud-client; name = "owncloud"; };
  __functor = _:
    {
      package ? pkgs.hello,
      type ? "electron",
      name ? null,
    }: let
      args = {
        qt = "--set QT_QPA_PLATFORM wayland";
        electron = ''
          --add-flags "--enable-features=UseOzonePlatform" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--force-device-scale-factor=2"
        '';
      };

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
          wrapProgram $out/bin/${binName} ${args.${type}}\
        '';
      };
}
