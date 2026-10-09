{
  flake,
  pkgs,
  ...
}: let
  source = ../modules/home/desktop/default/options/desktop-theme;
  theme = flake.nixosConfigurations.kit.config.home-manager.users.jon.programs.desktop-theme;
in
  # Theme switching takes a lock, swaps state atomically, and keeps the last good selection.
  pkgs.runCommand "desktop-theme-check" {nativeBuildInputs = [pkgs.util-linux];} ''
    bash ${source}/test.sh ${source} ${theme.assets}
    touch "$out"
  ''
