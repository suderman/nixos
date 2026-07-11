{
  flake,
  pkgs,
  ...
}: let
  pin = flake.inputs.pins.default.firefox.easy-container-shortcuts;
in
  pkgs.stdenv.mkDerivation {
    name = "${pin.pname}-${pin.version}";

    src = pkgs.fetchurl {
      inherit (pin) url sha256;
    };

    preferLocalBuild = true;
    allowSubstitutes = true;

    passthru = {
      inherit (pin) addonId;
    };

    buildCommand = ''
      dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
      mkdir -p "$dst"
      install -v -m644 "$src" "$dst/${pin.pname}@extraAddons.xpi"
    '';

    meta = with pkgs.lib; {
      description = "Easy, opinionated keyboard shortcuts for Firefox containers";
      license = licenses.bsd2;
      mozPermissions = [
        "tabs"
        "contextualIdentities"
        "cookies"
      ];
      platforms = platforms.all;
    };
  }
