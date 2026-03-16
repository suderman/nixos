{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.toolchains.native;
in {
  options.toolchains.native.enable = lib.mkEnableOption "native";
  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.gcc
      pkgs.gnumake
      pkgs.cmakeMinimal
      pkgs.pkg-config
      pkgs.autoconf
      pkgs.automake
      pkgs.libtool
    ];
  };
}
