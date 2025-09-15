# services.arr.enable = true;
{
  lib,
  flake,
  ...
}: let
in {
  imports = flake.lib.ls ./.;
  options.services.arr.enable = lib.options.mkEnableOption "arr";
}
