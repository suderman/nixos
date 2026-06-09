{
  inputs,
  pkgs,
  ...
}: let
  treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
in
  treefmtEval.config.build.wrapper
