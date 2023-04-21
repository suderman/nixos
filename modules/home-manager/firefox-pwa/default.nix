{ config, lib, pkgs, ... }: 

let

  inherit (lib) types;
  cfg = config.modules.firefox-pwa;

in {

  options.modules.firefox-pwa = {
    enable = lib.mkEnableOption (lib.mdDoc "enable");
    package = lib.mkOption {
      type = types.package;
      default = pkgs.firefox-pwa;
    };
    firefoxPackage = lib.mkOption {
      type = types.package;
      default = pkgs.firefox;
    };
    executables = lib.mkOption {
      type = types.path;
      readOnly = true;
      default = "${cfg.package}/bin";
    };
    sysData = lib.mkOption {
      type = types.path;
      readOnly = true;
      default = "${cfg.package}/share/firefoxpwa";
    };
    userData = lib.mkOption {
      type = types.path;
      default = "${config.xdg.dataHome}/firefoxpwa";
    };
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      FFPWA_EXECUTABLES = cfg.executables;
      FFPWA_SYSDATA = cfg.sysData;
      FFPWA_USERDATA = cfg.userData;
    };
    programs.firefox.package = cfg.firefoxPackage.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
      postFixup = ''
        wrapProgram ${lib.getExe cfg.firefoxPackage} \
          --set FFPWA_EXECUTABLES '${cfg.executables}' \
          --set FFPWA_SYSDATA '${cfg.sysData}' \
          --set FFPWA_USERDATA '${cfg.userData}'
      '';
    });
    home.file.".mozilla/native-messaging-hosts/firefoxpwa.json".source = "${cfg.package}/lib/mozilla/native-messaging-hosts/firefoxpwa.json";
    home.packages = [cfg.package];
  };

}
