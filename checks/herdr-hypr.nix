{
  flake,
  pkgs,
  ...
}: let
  cog = flake.nixosConfigurations.cog.config.home-manager.users.jon;
  kit = flake.nixosConfigurations.kit.config.home-manager.users.jon;
  module = ../modules/home/desktop/hyprland/herdr-hypr;
in
  assert cog.programs.herdr-hypr.enable;
  assert !kit.programs.herdr-hypr.enable;
    pkgs.runCommand "herdr-hypr-check" {nativeBuildInputs = [pkgs.python3];} ''
      export PYTHONDONTWRITEBYTECODE=1
      python ${module}/test-herdr-hypr.py
      test -x ${cog.programs.herdr-hypr.package}/bin/herdr-hypr
      touch "$out"
    ''
