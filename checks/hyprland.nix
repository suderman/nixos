{
  flake,
  pkgs,
  ...
}: let
  lib = pkgs.lib;
  hyprland = flake.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  source = ../modules/home/desktop/hyprland;
  profiles = [
    ["kit" "jon"]
    ["pow" "jon"]
    ["cog" "jon"]
    ["cog" "ness"]
    ["sim" "jon"]
  ];
  renderProfile = profile: let
    host = lib.concatStringsSep "-" profile;
    cfg = flake.nixosConfigurations.${builtins.head profile}.config.home-manager.users.${lib.last profile};
    files = lib.filterAttrs (_: file: lib.hasPrefix ".config/hypr/" file.target) cfg.home.file;
  in
    lib.concatStringsSep "\n" (lib.mapAttrsToList (_: file: let
        target = lib.removePrefix ".config/hypr/" file.target;
      in ''
        mkdir -p "$out/${host}/$(dirname ${lib.escapeShellArg target})"
        cp -r ${lib.escapeShellArg (builtins.path {path = file.source;})} "$out/${host}/"${lib.escapeShellArg target}
      '')
      files)
    + ''
      echo "Checking ${host} with pinned Hyprland"
      Hyprland --verify-config -c "$out/${host}/hyprland.lua"
    '';
in
  pkgs.runCommand "hyprland-check" {
    nativeBuildInputs = [pkgs.lua5_4 pkgs.bash (lib.getBin hyprland)];
  } ''
    find ${source}/lua -name '*.lua' -exec luac -p {} \;
    for script in ${source}/hypr/scripts/*.sh; do
      bash -n "$script"
    done
    # QR captures must stay out of clipboard history.
    bash ${source}/test-capture.sh ${source}/capture-read.sh
    export HOME="$TMPDIR/home" XDG_CONFIG_HOME="$TMPDIR/home/.config" XDG_RUNTIME_DIR="$TMPDIR/runtime"
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
    ${lib.concatMapStringsSep "\n" renderProfile profiles}
  ''
