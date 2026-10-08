{
  flake,
  pkgs,
  ...
}: let
  module = ../modules/nixos/desktop/default/options/sunshine;
  sunshine = flake.nixosConfigurations.kit.config.services.sunshine.package;
in
  # Retain the regression for the capture guard that prevents pending-frame growth.
  assert builtins.elem (module + "/wlr-pending-frame.patch") sunshine.patches;
    pkgs.runCommand "sunshine-check" {
      nativeBuildInputs = [pkgs.python3 pkgs.patch pkgs.stdenv.cc];
    } ''
      cp -r ${sunshine.src} source
      chmod -R u+w source
      cd source
      patch -p1 --fuzz=0 < ${module}/wlr-pending-frame.patch
      python ${module}/sunshine-wlr-pending-frame.py src/platform/linux/wlgrab.cpp
      touch "$out"
    ''
