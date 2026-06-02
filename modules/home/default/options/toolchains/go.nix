{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.toolchains.go;
  goDir = ".local/share/go";
  goCacheDir = ".cache/go-build";
in {
  options.toolchains.go.enable = lib.mkEnableOption "go";

  config = lib.mkIf cfg.enable {
    persist.scratch.directories = [goDir goCacheDir];

    home.sessionVariables = rec {
      GOPATH = "${config.home.homeDirectory}/${goDir}";
      GOBIN = "${GOPATH}/bin";
      GOMODCACHE = "${GOPATH}/pkg/mod";
      GOCACHE = "${config.home.homeDirectory}/${goCacheDir}";
    };

    home.sessionPath = [
      "${config.home.homeDirectory}/${goDir}/bin"
    ];

    home.packages = [
      pkgs.go # go gofmt
      pkgs.gopls # gopls
    ];

    # allow for native tooling too
    toolchains.native.enable = true;
  };
}
