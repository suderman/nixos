{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.toolchains.python;
  pipxDir = ".local/share/pipx";
  uvDir = ".local/share/uv";
in {
  options.toolchains.python.enable = lib.mkEnableOption "python";

  config = lib.mkIf cfg.enable {
    persist.scratch.directories = [pipxDir uvDir];

    home.sessionVariables = rec {
      PIPX_HOME = "${config.home.homeDirectory}/${pipxDir}";
      PIPX_BIN_DIR = "${PIPX_HOME}/bin";
      UV_TOOL_BIN_DIR = "${config.home.homeDirectory}/${uvDir}/bin";
    };

    home.sessionPath = [
      "${config.home.homeDirectory}/${pipxDir}/bin"
      "${config.home.homeDirectory}/${uvDir}/bin"
    ];

    home.packages = [
      pkgs.python3 # python python-config pydoc idle
      pkgs.pipx # pipx
      pkgs.uv # uv uvx
    ];

    # allow for native tooling too
    toolchains.native.enable = true;
  };
}
