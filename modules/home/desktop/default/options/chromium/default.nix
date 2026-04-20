{
  config,
  osConfig,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.programs.chromium;
  inherit (lib) mkIf mkOption types;
  inherit (config.lib.keyd) mkClass;
  inherit (config.lib.chromium) switches;
  inherit (perSystem.self) mkScript;

  # home-manager module expects this default directory
  dataDir = ".config/chromium";

  # Window class name
  class = "chromium-browser";
in {
  # Import chromium lib
  imports = [./lib.nix ./chrome-devtools-mcp.nix];

  # Extra options to manage external extensions
  options.programs.chromium = {
    dataDir = mkOption {
      type = types.path; # ~/.config/chromium
      default = "${config.home.homeDirectory}/${dataDir}";
      readOnly = true;
    };

    # Registry of chromium extensions
    registry = mkOption {
      type = types.anything;
      default = import ./registry.nix;
      readOnly = true;
    };

    # Extensions to automatically download and include
    externalExtensions = mkOption {
      type = types.anything;
      default = {};
    };

    # Extensions to automatically download and include unpacked
    unpackedExtensions = mkOption {
      type = types.anything;
      default = {inherit (cfg.registry) chromium-web-store;};
    };

    # chrome-devtools-mcp
    remoteDebuggingPort = mkOption {
      type = types.port;
      default = 9222 + config.home.portOffset;
    };
  };

  config = mkIf cfg.enable {
    # using Chromium without Google
    programs.chromium = {
      package = osConfig.programs.chromium.package;
      dictionaries = [pkgs.hunspellDictsChromium.en_US];
      commandLineArgs = switches;
    };

    # Persist reboots but skip backups
    persist.scratch.directories = [dataDir];

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {
      "alt.f" = "C-f"; # find in page
      "super.[" = "C-S-tab"; # prev tab
      "super.]" = "macro(C-tab)"; # next tab
      "super.w" = "C-w"; # close tab
      "super.t" = "C-t"; # new tab
      # "super.n" = "C-n"; # new window
      "super.r" = "C-r"; # reload
    };

    # tag Chromium and Picture-in-Picture windows
    wayland.windowManager.hyprland.settings = {
      windowrule = [
        "tag +web, match:class (${class})"
        "tag +pip, match:title ^(Picture-in-Picture)$"
      ];
    };

    # Share switches with electron apps in ~/.config
    xdg.configFile = let
      configs =
        ["chromium-flags.conf" "electron-flags.conf"]
        ++ (map (v: "electron-flags${toString v}.conf") (lib.range 14 40));
      value = {text = lib.concatStringsSep "\n" switches;};
    in
      builtins.listToAttrs (map (name: {inherit name value;}) configs);

    # Populate ~/.config/chromium/External Extensions
    systemd.user = let
      extNames = builtins.attrNames (cfg.externalExtensions // cfg.unpackedExtensions);
      crxDir = osConfig.programs.chromium.dataDir;
      extDir = "${cfg.dataDir}/External Extensions";
    in {
      # Symlink extensions from persistent storage
      services.crx = {
        Unit = {
          Description = "Symlink chromium extentions";
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${mkScript (
            # bash
            ''
              # Ensure external extensions directory exists
              dir="${extDir}"
              mkdir -p "$dir"

              # Change dirctory and clear it out
              cd "$dir"
              rm -f *.json

              # Enable nullglob
              shopt -s nullglob

              # Symlink each extension's json here
              symlink() {
                for json in ${crxDir}/$1/*.json; do
                  ln -sf $json .
                done
              }

              # External extensions
            ''
            + builtins.concatStringsSep "\n" (
              map (name: "symlink ${name}") extNames
            )
            # bash
            + ''


              # Disable nullglob again
              shopt -u nullglob
            ''
          )}";
          Restart = "no";
          RestartSec = 5;
        };
        Install.WantedBy = ["default.target"];
      };

      # Watch persistent storage for updates
      paths.crx = {
        Unit.Description = "Symlink chromium extentions";
        Path = {
          PathChanged = "${crxDir}/last";
          Unit = "crx.service";
        };
        Install.WantedBy = ["default.target"];
      };
    };

    # chrome-devtools-mcp wrapper with flock
    home.packages = let
      port = toString cfg.remoteDebuggingPort;
    in [
      (mkScript {
        name = "chrome-devtools-${port}";
        path = with pkgs; [procps util-linux nodejs];
        text =
          # bash
          ''
            lock="''${XDG_RUNTIME_DIR:-$HOME/.local/state}/chrome-devtools-mcp-${port}.lock"
            mkdir -p "$(dirname "$lock")"

            exec 9>"$lock"
            if ! flock -n -E 200 9; then
              rc=$?
              if [ "$rc" -eq 200 ]; then
                echo "chrome-devtools-mcp on :${port} is already in use" >&2
                exit 1
              fi
              exit "$rc"
            fi

            while IFS= read -r pid; do
              [ -n "$pid" ] || continue
              [ "$pid" = "$$" ] && continue
              kill "$pid" 2>/dev/null || true
            done < <(pgrep -f "chrome-devtools-mcp.*127\\.0\\.0\\.1:${port}" || true)

            exec npx -y chrome-devtools-mcp@latest --browser-url=http://127.0.0.1:${port}
          '';
      })
    ];
  };
}
