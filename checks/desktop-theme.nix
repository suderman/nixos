{
  flake,
  pkgs,
  ...
}: let
  lib = pkgs.lib;
  source = ../modules/home/desktop/default/options/desktop-theme;
  hosts = ["kit" "pow" "cog" "sim"];
  checkHost = host: let
    system = flake.nixosConfigurations.${host}.config;
    cfg = system.home-manager.users.jon;
    theme = cfg.programs.desktop-theme;
  in
    assert theme.enable;
    assert !cfg.stylix.targets.rofi.enable;
    assert !cfg.stylix.targets.waybar.enable;
    assert !cfg.stylix.targets.mako.enable;
    assert !(system.specialisation ? light);
    assert !(cfg.xdg.configFile ? "hypr/hyprland.conf"); ''
      echo "Checking ${host} appearance assets"
      bash ${source}/test.sh ${source} ${theme.assets}
      lua ${source}/test-appearance.lua ${../modules/home/desktop/hyprland/lua} ${theme.assets}
      test ! -s ${cfg.xdg.configFile."gtk-3.0/gtk.css".source}
      for mode in dark light; do
        grep -q '@import url(' ${cfg.gtk.theme.package}/share/themes/desktop-$mode/gtk-3.0/gtk.css
      done
      for mode in dark light; do
        css=$(awk -F '\"' '/^@import/{print $2}' ${theme.assets}/$mode/gtk.css)
        grep -q '@define-color window_bg_color' "$css"
        ! grep -q '{{' "$css"
        ! grep -q '{{' ${theme.assets}/$mode/kitty.conf
      done
      mkdir -p "$out/${host}/bin"
      ln -s ${theme.assets} "$out/${host}/assets"
      ln -s ${lib.getExe theme.package} "$out/${host}/bin/desktop-theme"
    '';
in
  pkgs.runCommand "desktop-theme-check" {
    nativeBuildInputs = with pkgs; [bash coreutils gnugrep gawk gnused findutils util-linux lua5_4];
  } ''
    bash ${../modules/home/desktop/hyprland/test-capture.sh} ${../modules/home/desktop/hyprland/capture-read.sh}
    ${lib.concatMapStringsSep "\n" checkHost hosts}
  ''
