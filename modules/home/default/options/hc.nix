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
  cfg = config.programs.hc;
  core = perSystem.herdr-nix.herdr-core;
  # Focus follows the mouse between panes, as in Hyprland: herdr-app PR #837,
  # pinned to its head commit. Drop the patch once a release includes it; the
  # settings below keep it on.
  app = perSystem.herdr-nix.herdr.overrideAttrs (old: {
    patches =
      (old.patches or [])
      ++ [
        (pkgs.fetchpatch {
          url = "https://github.com/herdrdev/herdr-app/compare/b67715e8985e6097f83f8120fc9b9e52e6596f50...0ff0474e14d316f35666c28611d0b74ca4019d76.diff";
          hash = "sha256-GMQXhjgAdcB8aEcQ4yunpFO/xF40CKe3NL+O+RgSRhM=";
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
  hc = "${core}/bin/hc";
  desktop = config.desktop.enable or false;

  # Add each listed host once; saved machines are skipped, so later runs need
  # no SSH. machine add never installs hc there without a terminal to ask in.
  addMachines = pkgs.self.mkScript {
    name = "hc-machines";
    path = [pkgs.jq];
    text = ''
      saved=$(${hc} machine ls --json)
      status=0
      for machine in ${lib.escapeShellArgs cfg.machines}; do
        if ! jq -e --arg name "$machine" 'any(.machines[]?; .name == $name)' <<<"$saved" >/dev/null; then
          ${hc} machine add "$machine" </dev/null || status=1
        fi
      done
      exit "$status"
    '';
  };
in {
  options.programs.hc = {
    enable = lib.mkEnableOption "Herdr Core (hc)";
    machines = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["cog" "lux"];
      description = "Other hosts this core adds as hc machines, reached over SSH, so their terminals show here as HOST/t7.";
    };
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

      # Any hc command starts a core when none runs, and the core passes the
      # environment of whoever started it to every terminal: an SSH session
      # without WAYLAND_DISPLAY, or a service's narrow PATH. Start it here first,
      # from the login session, after the desktop's environment is imported.
      systemd.user.services.hc = {
        Unit = {
          Description = "Start herdr-core with the login session's environment";
          After = lib.optional desktop "graphical-session.target";
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${hc} server start";
        };
        Install.WantedBy = [(if desktop then "graphical-session.target" else "default.target")];
      };

      # An asleep or offline host retries later instead of blocking login.
      systemd.user.services.hc-machines = lib.mkIf (cfg.machines != []) {
        Unit = {
          Description = "Add the other hosts as hc machines";
          After = ["hc.service"];
          StartLimitIntervalSec = 0;
        };
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe addMachines;
          Restart = "on-failure";
          RestartSec = 300;
        };
        Install.WantedBy = ["default.target"];
      };
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
          // cfg.app.settings);
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
    (lib.optionalAttrs (options.services ? keyd) (lib.mkIf cfg.app.enable {
      services.keyd.windows.herdr-app."super.w" = "A-w";
    }))
  ];
}
