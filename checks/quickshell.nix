{
  flake,
  pkgs,
  ...
}: let
  lib = pkgs.lib;
  source = ../modules/home/desktop/hyprland/quickshell;
  names = map (n: "base${n}") ["00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "0A" "0B" "0C" "0D" "0E" "0F"];
  hosts = ["kit" "cog"];
  checkHost = host: let
    cfg = flake.nixosConfigurations.${host}.config.home-manager.users.jon;
    qs = cfg.programs.quickshell;
    theme = cfg.programs.desktop-theme;
  in
    assert !cfg.services.avizo.enable;
    assert cfg.wayland.windowManager.hyprland.quickshell.files ? "MediaOsd.qml"; ''
      echo "Checking ${host} Quickshell appearance"
      python3 ${source}/test-theme.py ${qs.package} ${qs.configs.hyprland} ${theme.assets} --default-mode ${theme.defaultMode}
      python3 ${source}/test-media-ipc.py ${qs.package} ${source}/media-osd-client.sh
      mkdir -p "$out/${host}/bin"
      ln -s ${lib.getExe (lib.findFirst (p: (p.meta.mainProgram or "") == "mediactl") null cfg.home.packages)} "$out/${host}/bin/mediactl"
      ln -s ${qs.configs.hyprland} "$out/${host}/config"
      ln -s ${theme.assets} "$out/${host}/assets"
    '';
  fallback = builtins.all (host: flake.nixosConfigurations.${host}.config.home-manager.users.jon.services.avizo.enable) ["pow" "sim"];
  staticSystem = flake.nixosConfigurations.kit.extendModules {
    modules = [{home-manager.users.jon.programs.desktop-theme.enable = lib.mkForce false;}];
  };
  static = staticSystem.config.home-manager.users.jon;
  staticPalette = pkgs.writeText "quickshell-expected-static-palette.json" (builtins.toJSON (lib.genAttrs names (n: "#${static.lib.stylix.colors.${n}}")));
in
  assert fallback;
    pkgs.runCommand "quickshell-check" {nativeBuildInputs = [pkgs.python3 pkgs.bash];} ''
      python3 ${source}/test-media.py ${pkgs.avizo} ${source}/media-osd-client.sh
      ${lib.concatMapStringsSep "\n" checkHost hosts}
      echo "Checking Quickshell with runtime themes disabled"
      python3 ${source}/test-theme.py ${static.programs.quickshell.package} ${static.programs.quickshell.configs.hyprland} ${staticPalette} --static --default-mode ${static.programs.desktop-theme.defaultMode}
      mkdir -p "$out/static"
      ln -s ${static.programs.quickshell.configs.hyprland} "$out/static/config"
      ln -s ${staticPalette} "$out/static/palette.json"
    ''
