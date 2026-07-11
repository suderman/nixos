{
  flake,
  pkgs,
  ...
}: let
  pin = flake.inputs.pins.default.fetchurl.eden;
  src = pkgs.fetchurl {
    inherit (pin) url sha256;
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
