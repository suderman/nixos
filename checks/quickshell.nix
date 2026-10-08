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
    assert cfg.services.hypridle.settings.general.before_sleep_cmd == "loginctl lock-session";
    assert cfg.services.hypridle.settings.general.inhibit_sleep == 3;
    assert cfg.programs.wlogout.enable;
    assert cfg.wayland.windowManager.hyprland.quickshell.files ? "MediaOsd.qml";
    assert cfg.wayland.windowManager.hyprland.quickshell.files ? "QuickSettings.qml";
    assert cfg.wayland.windowManager.hyprland.quickshell.files ? "AudioControls.qml";
    assert cfg.wayland.windowManager.hyprland.quickshell.files ? "BluetoothControls.qml";
    assert cfg.wayland.windowManager.hyprland.quickshell.files ? "BrightnessControls.qml";
    assert cfg.wayland.windowManager.hyprland.quickshell.files ? "NetworkControls.qml";
    assert lib.takeEnd 2 cfg.programs.waybar.settings.bar.modules-right == ["custom/quick-settings" "custom/power"]; ''
      echo "Checking ${host} Quickshell appearance"
      python3 ${source}/test-theme.py ${qs.package} ${qs.configs.hyprland} ${theme.assets} --default-mode ${theme.defaultMode}
      python3 ${source}/test-media-ipc.py ${qs.package} ${source}/media-osd-client.sh
      python3 ${source}/test-settings.py ${qs.configs.hyprland}
      python3 ${source}/test-backlight.py ${lib.getExe (lib.findFirst (p: (p.meta.mainProgram or "") == "mediactl") null cfg.home.packages)}
      mkdir -p "$out/${host}/bin"
      ln -s ${lib.getExe (lib.findFirst (p: (p.meta.mainProgram or "") == "mediactl") null cfg.home.packages)} "$out/${host}/bin/mediactl"
      ln -s ${qs.configs.hyprland} "$out/${host}/config"
      ln -s ${cfg.xdg.configFile."pipewire/client.conf.d/90-quickshell.conf".source} "$out/${host}/pipewire-client.conf"
      ln -s ${cfg.xdg.configFile."hypr/hypridle.conf".source} "$out/${host}/hypridle.conf"
      ln -s ${cfg.services.hypridle.package}/bin/hypridle "$out/${host}/bin/hypridle"
      ln -s ${pkgs.writeText "quick-settings-waybar.json" (builtins.toJSON cfg.programs.waybar.settings.bar)} "$out/${host}/waybar.json"
      ln -s ${pkgs.writeText "quick-settings-waybar.css" cfg.programs.waybar.style} "$out/${host}/waybar.css"
      ln -s ${theme.assets} "$out/${host}/assets"
    '';
  fallback = builtins.all (host: let
    cfg = flake.nixosConfigurations.${host}.config.home-manager.users.jon;
  in
    cfg.services.avizo.enable && !(cfg.wayland.windowManager.hyprland.quickshell.files ? "QuickSettings.qml") && !(cfg.wayland.windowManager.hyprland.quickshell.files ? "AudioControls.qml") && !(cfg.wayland.windowManager.hyprland.quickshell.files ? "BluetoothControls.qml") && !(cfg.wayland.windowManager.hyprland.quickshell.files ? "BrightnessControls.qml") && !(cfg.wayland.windowManager.hyprland.quickshell.files ? "NetworkControls.qml")) ["pow" "sim"];
  staticSystem = flake.nixosConfigurations.kit.extendModules {
    modules = [{home-manager.users.jon.programs.desktop-theme.enable = lib.mkForce false;}];
  };
  static = staticSystem.config.home-manager.users.jon;
  staticPalette = pkgs.writeText "quickshell-expected-static-palette.json" (builtins.toJSON (lib.genAttrs names (n: "#${static.lib.stylix.colors.${n}}")));
in
  assert fallback;
    pkgs.runCommand "quickshell-check" {nativeBuildInputs = [pkgs.python3 pkgs.bash];} ''
      mkdir -p "$out"
      python3 ${source}/test-media.py ${pkgs.avizo} ${source}/media-osd-client.sh
      ${lib.concatMapStringsSep "\n" checkHost hosts}
      echo "Checking Quickshell with runtime themes disabled"
      python3 ${source}/test-theme.py ${static.programs.quickshell.package} ${static.programs.quickshell.configs.hyprland} ${staticPalette} --static --default-mode ${static.programs.desktop-theme.defaultMode}
      mkdir -p "$out/static"
      ln -s ${static.programs.quickshell.configs.hyprland} "$out/static/config"
      ln -s ${staticPalette} "$out/static/palette.json"
    ''
