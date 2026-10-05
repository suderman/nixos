{
  flake,
  pkgs,
  ...
}: let
  lib = pkgs.lib;
  hyprland = flake.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  source = ../modules/home/desktop/hyprland;
  hosts = ["kit" "pow" "cog" "sim"];
  renderHost = host: let
    cfg = flake.nixosConfigurations.${host}.config.home-manager.users.jon;
    files = lib.filterAttrs (_: file: lib.hasPrefix ".config/hypr/" file.target) cfg.home.file;
    scripts = builtins.filter (package: lib.hasPrefix "hypr-" (package.meta.mainProgram or "")) cfg.home.packages;
    widgets = ["windows" "layout-dwindle" "layout-master" "layout-scrolling" "layout-monocle"];
  in
    assert cfg.wayland.windowManager.hyprland.configType == "lua";
    assert !cfg.services.keyd.mapper.enable;
    assert !(cfg.xdg.configFile ? "hypr/hyprland.conf");
      lib.concatStringsSep "\n" (lib.mapAttrsToList (_: file: let
          target = lib.removePrefix ".config/hypr/" file.target;
        in ''
          mkdir -p "$out/${host}/$(dirname ${lib.escapeShellArg target})"
          cp ${lib.escapeShellArg (builtins.path {path = file.source;})} "$out/${host}/"${lib.escapeShellArg target}
        '')
        files)
      + ''
        cp ${pkgs.writeText "${host}-waybar.json" (builtins.toJSON cfg.programs.waybar.settings.bar)} "$out/${host}/waybar.json"
        mkdir -p "$out/${host}/bin"
        ${lib.concatMapStringsSep "\n" (package: ''
            ln -s ${lib.getExe package} "$out/${host}/bin/${package.meta.mainProgram}"
          '')
          scripts}
        ${lib.concatMapStringsSep "\n" (widget: ''
            ln -s ${cfg.programs.waybar.settings.bar."custom/${widget}".exec} "$out/${host}/bin/status-${widget}"
            bash -n "$out/${host}/bin/status-${widget}"
          '')
          widgets}
        echo "Checking ${host} with pinned Hyprland"
        Hyprland --verify-config -c "$out/${host}/hyprland.lua"
      '';
in
  pkgs.runCommand "hyprland-check" {
    nativeBuildInputs = [pkgs.lua5_4 pkgs.bash pkgs.jq (lib.getBin hyprland)];
  } ''
    lua ${source}/test.lua ${source}/lua
    bash ${source}/test-workspace.sh ${source}/hypr/scripts/hypr-activeworkspace.sh
    find ${source}/lua -name '*.lua' -exec luac -p {} \;
    for script in ${source}/hypr/scripts/*.sh; do
      bash -n "$script"
    done
    export HOME="$TMPDIR/home" XDG_CONFIG_HOME="$TMPDIR/home/.config" XDG_RUNTIME_DIR="$TMPDIR/runtime"
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
    ${lib.concatMapStringsSep "\n" renderHost hosts}
  ''
