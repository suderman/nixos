{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.programs.hrvst-cli;
  pin = flake.inputs.pins.default.npm.hrvst-cli;

  package = pkgs.buildNpmPackage {
    inherit (pin) pname version npmDepsHash;

    src = pkgs.fetchurl {inherit (pin) url hash;};
    nodejs = pkgs.nodejs_22;

    postPatch = "cp ${pin.packageLock} package-lock.json";
    npmInstallFlags = ["--omit=dev"];
    dontNpmBuild = true;

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      HRVST_COMPLETION=1 $out/bin/hrvst --help >/dev/null
      runHook postInstallCheck
    '';

    passthru = {inherit (pin) upstream;};
    meta = {
      inherit (pin) description;
      homepage = "https://github.com/kgajera/hrvst-cli";
      downloadPage = pin.upstream;
      license = pkgs.lib.licenses.mit;
      mainProgram = "hrvst";
    };
  };
in {
  options.programs.hrvst-cli.enable = lib.mkEnableOption "hrvst-cli";

  config = lib.mkIf cfg.enable {
    home.packages = [package];

    persist.scratch.directories = [
      {
        directory = ".hrvst";
        mode = "0700";
      }
    ];
  };
}
