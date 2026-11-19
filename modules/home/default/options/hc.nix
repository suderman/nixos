{
  config,
  flake,
  lib,
  osConfig,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.hc;
  core = perSystem.herdr-nix.herdr-core;
  app = perSystem.herdr-nix.herdr;
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
  layouts = pkgs.runCommand "herdr-app-stylix-layouts" {nativeBuildInputs = [pkgs.jq];} ''
    mkdir "$out"
    jq '. + {window_blur: true, terminal_opacity: 0.40, theme: {light: "stylix-light", dark: "stylix-dark"}}' \
      ${app.src}/defaults/layouts/main.json > "$out/stylix.json"
  '';
in {
  options.programs.hc = {
    enable = lib.mkEnableOption "Herdr Core (hc)";
    app = {
      enable = lib.mkEnableOption "the Herdr desktop app and Herdr Core";
      settings = lib.mkOption {
        inherit (json) type;
        default = {};
        description = "Herdr app settings to merge into its writable settings.json.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # The TUI module already installs Edger when both stacks are enabled.
      home.packages =
        [core]
        ++ lib.optional (!config.programs.herdr.enable) (pkgs.self.mkScript {
          name = "edger";
          path = [core];
          text = builtins.readFile "${flake.inputs.edger}/bin/edger";
        });
      persist.storage.directories = [
        {
          directory = ".config/herdr-core";
          mode = "0700";
        }
      ];
      # Core stores layouts and machine records alongside unencrypted terminal history.
      persist.scratch.directories = [
        {
          directory = ".local/state/herdr-core";
          mode = "0700";
        }
      ];
    })

    (lib.mkIf cfg.app.enable {
      programs.hc.enable = true;
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

              "alt-z ?" = "app.help";
              "alt-z s" = "app.settings";
              "alt-shift-n" = "space.new";
              "alt-z ." = "space.rename";
              "alt-z shift-d" = "space.close";
              "alt-a" = "mod.open:picker";
              "alt-z d" = "window.close";

              "alt-shift-t" = "tab.new";
              "alt-z ," = "tab.rename";
              "alt-z shift-x" = "tab.close";
              "alt-z [" = "tab.prev";
              "alt-z ]" = "tab.next";
              "alt-z {" = {
                command = "tab.move";
                args.by = -1;
              };
              "alt-z }" = {
                command = "tab.move";
                args.by = 1;
              };
              "alt-z m" = "terminal.select";

              "alt-z u" = "pane.split:down";
              "alt-z i" = "pane.split:right";
              "alt-shift-w" = "pane.close";
              "alt-z h" = "pane.go:left";
              "alt-z j" = "pane.go:down";
              "alt-z k" = "pane.go:up";
              "alt-z l" = "pane.go:right";
              "alt-z shift-h" = "pane.swap:left";
              "alt-z shift-j" = "pane.swap:down";
              "alt-z shift-k" = "pane.swap:up";
              "alt-z shift-l" = "pane.swap:right";
              "alt-z z" = "pane.zoom";
              "alt-z b" = "layout.toggle:sidebar";

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
            // builtins.listToAttrs (map (n: lib.nameValuePair "alt-z ${toString n}" "tab.select:${toString n}") (lib.range 1 9))
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
        settings = json.generate "hc-app-settings.json" ({core = lib.getExe core;} // fonts // cfg.app.settings);
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
  ];
}
