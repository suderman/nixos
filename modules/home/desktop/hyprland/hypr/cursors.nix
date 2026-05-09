{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
in {
  home.packages = [pkgs.hyprcursor];
}
