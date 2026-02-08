{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.python;
  pipxDir = ".local/share/pipx";
in {
  options.programs.python.enable = lib.mkEnableOption "python";

  config = lib.mkIf cfg.enable {
    persist.scratch.directories = [pipxDir];

    home.sessionVariables = rec {
      PIPX_HOME = "${config.home.homeDirectory}/${pipxDir}";
      PIPX_BIN_DIR = "${PIPX_HOME}/bin";
    };

    home.sessionPath = [
      "${config.home.homeDirectory}/${pipxDir}/bin"
    ];

    home.packages = [
      pkgs.python3 # python python-config pydoc idle
      pkgs.pipx # pipx
    ];
  };
}
