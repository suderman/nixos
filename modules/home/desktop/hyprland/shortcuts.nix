{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}: let
  mappings = scope: sections:
    lib.concatLists (lib.mapAttrsToList (
        section: keys:
          lib.mapAttrsToList (key: action: {
            inherit key;
            context = "${scope}/${section}";
            description = toString action;
          })
          keys
      )
      sections);
  system = lib.concatLists (lib.mapAttrsToList (keyboard: cfg: mappings "keyboard:${keyboard}" cfg.settings) osConfig.services.keyd.keyboards);
  windows = mappings "app" (config.lib.keyd.expandHomeRowModifierRules config.services.keyd.windows);
  layers = mappings "layer" (config.lib.keyd.expandHomeRowModifierRules config.services.keyd.layers);
  keyd = pkgs.writeText "desktop-keyd-shortcuts.json" (builtins.toJSON (system ++ windows ++ layers));
  command = pkgs.writeShellApplication {
    name = "desktop-shortcuts";
    runtimeInputs = [pkgs.jq config.programs.rofi.package];
    text = ''
      list() {
        hyprctl -j binds | jq -r '
          .[] | . as $bind |
          ([[64,"Super"],[8,"Alt"],[4,"Ctrl"],[1,"Shift"]] |
            map(select(($bind.modmask / .[0] | floor) % 2 == 1) | .[1]) |
            . + [$bind.key] | join("+")) as $key |
          [$key,
           (if .longPress then "hold" elif .release then "release" else "press" end),
           (if .description != "" then .description else (.dispatcher + " " + .arg) end),
           (if .submap != "" then .submap else "Hyprland" end)] | @tsv'
        jq -r '.[] | [.key, "keyd", .description, .context] | @tsv' ${keyd}
      }
      case "''${1:-}" in
        --list) list ;;
        "")
          list | rofi -dmenu -i -no-custom -p Shortcuts \
            -mesg 'Search keys, actions, apps, or keyd layers. This list does not execute actions.' \
            -theme-str 'window { width: 85%; } listview { lines: 20; }' >/dev/null || [[ $? == 1 ]]
          ;;
        *) printf 'Usage: desktop-shortcuts [--list]\n' >&2; exit 64 ;;
      esac
    '';
  };
in {
  home.packages = [command];
  wayland.windowManager.hyprland.lua.features.shortcuts = ''
    util.exec("SUPER + F1", "desktop-shortcuts", { description = "Search desktop and keyd shortcuts" })
  '';
}
