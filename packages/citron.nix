{
  flake,
  pkgs,
  ...
}: let
  pin = flake.inputs.pins.default.fetchurl.citron;
  src = pkgs.fetchurl {
    inherit (pin) url;
    # The central pin has the wrong hash for this nightly's v3 AppImage.
    sha256 =
      if pin.version == "nightly-40212aa3e"
      then "sha256-5CbKZoCXT1LhZaf2zG1VmsHzQKPDzDNQf1T5k9vwP2M="
      else pin.sha256;
  };
in
  pkgs.stdenvNoCC.mkDerivation {
    inherit (pin) pname version;
    inherit src;

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      printf '%s\n' "$src" > $out/path

      runHook postInstall
    '';

    passthru = {
      inherit src;
      inherit (pin) upstream url;
    };

    meta = {
      inherit (pin) description;
      platforms = ["x86_64-linux"];
      sourceProvenance = [pkgs.lib.sourceTypes.binaryNativeCode];
    };
  }
