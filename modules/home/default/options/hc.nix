{
  config,
  flake,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.hc;
  core = perSystem.herdr-nix.herdr-core;
  app = perSystem.herdr-nix.herdr;
  edgerMod = "${flake.inputs.edger}/herdr-app/mods/edger";
  json = pkgs.formats.json {};
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

              # These resize in Edger. The app defaults would swap panes instead.
              "alt-shift-h" = "terminal";
              "alt-shift-j" = "terminal";
              "alt-shift-k" = "terminal";
              "alt-shift-l" = "terminal";
            }
            // builtins.listToAttrs (map (n: lib.nameValuePair "alt-z ${toString n}" "tab.select:${toString n}") (lib.range 1 9));
        };
      in
        pkgs.runCommand "herdr-app-keys.json" {nativeBuildInputs = [pkgs.jq];} ''
          jq -s '.[0] * .[1]' ${app.src}/defaults/keys.json ${overrides} > "$out"
        '';

      # The app writes both files, so leave them writable and update only managed entries.
      home.activation.hcAppSettings = let
        settings = json.generate "hc-app-settings.json" ({core = lib.getExe core;} // cfg.app.settings);
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
            for layout in ${app.src}/defaults/layouts/*.json "$dir"/layouts/*.json; do
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
