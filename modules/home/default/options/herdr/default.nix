# The Herdr desktop app, a client of herdr-core (services.herdr, in core.nix
# beside this file). The Herdr TUI it replaces is programs.herdr-tui.
{
  config,
  flake,
  lib,
  options,
  osConfig,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.herdr;
  core = config.services.herdr.finalPackage;
  # Focus follows the mouse between panes, as in Hyprland: herdr-app PR #837,
  # pinned to its head commit. Drop the patch once a release includes it; the
  # settings below keep it on.
  app = perSystem.herdr-nix.herdr.overrideAttrs (old: {
    patches =
      (old.patches or [])
      ++ [
        (pkgs.fetchpatch {
          url = "https://github.com/herdrdev/herdr-app/compare/2d1464e02ddad5484eaaf9a5b59b594e3930aeba...0fcd2da58553024c533988a7f51f41279a97664a.diff";
          hash = "sha256-Tog8GHYmXTUj6GJNcCOG3xVnDADhWqEA4ora6w9DPTI=";
        })
      ];
  });
  edgerMod = "${flake.inputs.edger}/herdr-app/mods/edger";
  json = pkgs.formats.json {};

  # Herdr app themes from the same Stylix light/dark pair as the desktop
  # theme, and a see-through copy of the app's own main layout that uses them.
  pair = osConfig.programs.stylix-theme-toggle or {enable = false;};
  stylix = config.stylix.enable && pair.enable;
  theme = mode: let
    colors = (config.stylix.base16.mkSchemeAttrs pair."${mode}Scheme").override config.stylix.override;
    hex = name: "#${colors.${name}}";
  in
    json.generate "herdr-app-stylix-${mode}.json" {
      # Kitty's base16 mapping, so terminals match the TUI in kitty.
      background = hex "base00";
      foreground = hex "base05";
      selection = hex "base03";
      cursor = hex "base05";
      ansi = map hex ["base00" "base08" "base0B" "base0A" "base0D" "base0E" "base0C" "base05" "base02" "base08" "base0B" "base0A" "base0D" "base0E" "base0C" "base07"];
      # The app paints several of these layers over each other. These alphas,
      # with the layout's terminal_opacity, put terminals and the sidebar at
      # about kitty's 0.85 over Hyprland's blur, and pane headers at 0.7
      # (measured in a sandbox).
      colors = {
        canvas = hex "base00" + "4d";
        chrome = hex "base00" + "8a";
        background = hex "base00" + "40";
        # Secondary text one palette step up, to stay readable over a busy
        # wallpaper; the app's own mixes fade toward the translucent panels.
        muted = hex "base05";
        dim = hex "base04";
      };
    };
  # Stylix fonts: sans for the app's own interface, mono for terminals.
  # Stylix sizes are points; the app's are pixels at zoom 1. The interface
  # has no size setting of its own.
  fonts = let
    inherit (config.stylix) fonts;
  in
    lib.optionalAttrs (config.stylix.enable or false) {
      font = fonts.monospace.name;
      ui_font = fonts.sansSerif.name;
      font_size = fonts.sizes.terminal * 4.0 / 3;
    };
  # Alt+Z, then one of these keys, through Edger's prefix popup, which waits
  # for the key and shows this list. Values are keys.json actions. Release
  # Alt first: Alt+U and the like are Edger's own keys.
  prefix =
    {
      "?" = "app.help";
      "s" = "app.settings";
      "." = "space.rename";
      "shift-d" = "space.close";
      "d" = "window.close";
      "," = "tab.rename";
      "shift-x" = "tab.close";
      "[" = "tab.prev";
      "]" = "tab.next";
      "{" = {
        command = "tab.move";
        args.by = -1;
      };
      "}" = {
        command = "tab.move";
        args.by = 1;
      };
      "m" = "edger.copy";
      "u" = "pane.split:down";
      "i" = "pane.split:right";
      "h" = "pane.go:left";
      "j" = "pane.go:down";
      "k" = "pane.go:up";
      "l" = "pane.go:right";
      "shift-h" = "pane.swap:left";
      "shift-j" = "pane.swap:down";
      "shift-k" = "pane.swap:up";
      "shift-l" = "pane.swap:right";
      "z" = "pane.zoom";
      "b" = "layout.toggle:sidebar";
    }
    // builtins.listToAttrs (map (n: lib.nameValuePair (toString n) "tab.select:${toString n}") (lib.range 1 9));
  layouts = pkgs.runCommand "herdr-app-stylix-layouts" {nativeBuildInputs = [pkgs.jq];} ''
    mkdir "$out"
    jq '. + {window_blur: true, terminal_opacity: 0.40, theme: {light: "stylix-light", dark: "stylix-dark"}}' \
      ${app.src}/defaults/layouts/main.json > "$out/stylix.json"
  '';
in {
  imports = [./core.nix];

  # Avoid duplicate options when a Home Manager release brings its own
  # programs.herdr, which configures the TUI.
  disabledModules = ["programs/herdr.nix"];

  options.programs.herdr = {
    enable = lib.mkEnableOption "the Herdr desktop app, with herdr-core";
    settings = lib.mkOption {
      inherit (json) type;
      default = {};
      description = "Herdr app settings to merge into its writable settings.json.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # A window app; a headless host runs herdr-core alone (services.herdr).
      assertions = [
        {
          assertion = config.desktop.enable or false;
          message = "programs.herdr is the Herdr desktop app; enable services.herdr alone on a host without a desktop";
        }
      ];
      services.herdr.enable = true;
      home.packages = [app];
      persist.storage.directories = [
        {
          directory = ".config/herdr-app";
          mode = "0700";
        }
      ];

      # Select it once with `herdr-app do layout.switch --name stylix`.
      xdg.configFile."herdr-app/themes/stylix-dark.json" = lib.mkIf stylix {source = theme "dark";};
      xdg.configFile."herdr-app/themes/stylix-light.json" = lib.mkIf stylix {source = theme "light";};
      xdg.configFile."herdr-app/layouts/stylix.json" = lib.mkIf stylix {source = "${layouts}/stylix.json";};

      # Link the whole directory so the app accepts the mod's relative imports.
      xdg.configFile."herdr-app/mods/edger".source = edgerMod;
      xdg.configFile."herdr-app/edger.json".source = json.generate "herdr-app-edger.json" {inherit prefix;};
      xdg.configFile."herdr-app/keys.json".source = let
        overrides = json.generate "hc-key-overrides.json" {
          global =
            {
              "alt-h" = "edger.left";
              "alt-j" = "edger.down";
              "alt-k" = "edger.up";
              "alt-l" = "edger.right";
              "alt-u" = "edger.horizontal";
              "alt-i" = "edger.vertical";
              "alt-w" = "edger.close";
              # Always a Herdr split, even with an editor focused.
              "alt-shift-u" = "pane.split:down";
              "alt-shift-i" = "pane.split:right";

              # Alt+Z opens Edger's prefix popup (edger.json).
              "alt-z" = "edger.prefix";
              "alt-shift-n" = "space.new";
              "alt-shift-t" = "tab.new";
              "alt-shift-w" = "pane.close";
              "alt-a" = "mod.open:picker";

              # Edger resizes editor windows first, then Herdr panes. The app
              # defaults would swap panes instead.
              "alt-shift-h" = "edger.resize-left";
              "alt-shift-j" = "edger.resize-down";
              "alt-shift-k" = "edger.resize-up";
              "alt-shift-l" = "edger.resize-right";

              # Super, not Ctrl, so programs in panes keep every Ctrl key.
              # These match kitty's Super keys where it has them.
              "super-=" = "app.zoom_in";
              "super-+" = "app.zoom_in";
              "super--" = "app.zoom_out";
              "super-0" = "app.zoom_reset";
              "super-[" = "tab.prev";
              "super-]" = "tab.next";
              "super-t" = "tab.new";
              "super-shift-p" = "app.palette";
              "super-?" = "app.help";
              "super-shift-/" = "app.help";
              "super-shift-?" = "app.help";
            }
            // builtins.listToAttrs (map (n: lib.nameValuePair "super-${toString n}" "tab.select:${toString n}") (lib.range 1 9));
          terminal = {
            "super-c" = "terminal.copy";
            "super-v" = "terminal.paste";
            "super-g" = "terminal.search";
          };
        };
      in
        pkgs.runCommand "herdr-app-keys.json" {nativeBuildInputs = [pkgs.jq];} ''
          # Drop the app's Ctrl keys, so programs get Ctrl+digits, Ctrl+arrows
          # and the rest unchanged. Ctrl+V stays: it pastes only an image and
          # otherwise reaches the program.
          jq -s '
            (.[0]
              | .global |= with_entries(select(.key | test("ctrl") | not))
              | .terminal |= with_entries(select(.key == "ctrl-v" or (.key | test("ctrl") | not))))
            * .[1]
          ' ${app.src}/defaults/keys.json ${overrides} > "$out"
        '';

      # The app writes both files, so leave them writable and update only managed entries.
      home.activation.hcAppSettings = let
        # The app's 150 ms focus delay lets the pointer sweep across panes.
        settings = json.generate "hc-app-settings.json" ({
            core = lib.getExe core;
            focus_follows_mouse = true;
          }
          // fonts
          // cfg.settings);
        configure = perSystem.self.mkScript {
          name = "hc-app-settings";
          path = [pkgs.jq];
          text = ''
            dir="$1"
            mkdir -p -m 700 "$dir"
            update() (
              file="$1"
              shift
              tmp=$(mktemp "$file.XXXXXX")
              trap 'rm -f "$tmp"' EXIT
              { if [[ -e "$file" ]]; then cat "$file"; else printf '{}\n'; fi; } |
                jq -se "$@" > "$tmp"
              mv -T "$tmp" "$file"
            )
            update "$dir/settings.json" --slurpfile settings ${settings} '.[0] * $settings[0]'

            # The app opens kept windows on startup and on layout changes.
            layouts=()
            for layout in ${app.src}/defaults/layouts/*.json ${lib.optionalString stylix "${layouts}/*.json"} "$dir"/layouts/*.json; do
              [[ ! -f "$layout" ]] || layouts+=("$(basename "$layout" .json)")
            done
            update "$dir/windows.json" --slurpfile mod ${edgerMod}/mod.json \
              'reduce $ARGS.positional[] as $layout (.[0]; .kept[$layout].edger = ($mod[0].overlay + {mod: "edger"}))' \
              --args "''${layouts[@]}"
          '';
        };
      in
        lib.hm.dag.entryAfter ["writeBoundary"] ''
          run ${lib.getExe configure} ${lib.escapeShellArg "${config.xdg.configHome}/herdr-app"}
        '';
    })

    # Hyprland's Super+W would close the whole app window. In the app it is
    # Alt+W instead, so Edger closes the editor window, pane, tab or space.
    (lib.optionalAttrs (options.services ? keyd) (lib.mkIf cfg.enable {
      services.keyd.windows.herdr-app."super.w" = "A-w";
    }))
  ];
}
