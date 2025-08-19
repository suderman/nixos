{ config, osConfig, lib, pkgs, perSystem, ... }: let

  cfg = config.programs.chromium;
  inherit (lib) mkIf mkOption types;
  inherit (config.services.keyd.lib) mkClass;
  inherit (config.programs.chromium.lib) switches;

  # Window class name
  class = "chromium-browser";

in {

  # Import chromium lib
  imports = [ ./lib.nix ];

  # Extra options to manage external extensions
  options.programs.chromium = {

    # home-manager module expects this default directory
    dataDir = mkOption {
      type = types.path;      # ~/.config/chromium
      default = "${config.xdg.configHome}/chromium";
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
      default = { inherit (cfg.registry) chromium-web-store; };
    };

  };

  config = mkIf cfg.enable {

    # using Chromium without Google
    programs.chromium = {
      package = osConfig.programs.chromium.package;
      dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
      commandLineArgs = switches;  
    };

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {
      "alt.f" = "C-f"; # find in page
      "super.[" = "C-S-tab"; # prev tab
      "super.]" = "macro(C-tab)"; # next tab
      "super.w" = "C-w"; # close tab
      "super.t" = "C-t"; # new tab
      "super.n" = "C-n"; # new window
      "super.r" = "C-r"; # reload
      "super.o" = "C-l"; # location bar
    };

    # tag Chromium and Picture-in-Picture windows
    wayland.windowManager.hyprland.settings = {
      windowrulev2 = [
        "tag +web2, class:(${class})"
        "tag +pip, title:^(Picture in picture)$"
      ];
    };

    # Share switches with electron apps in ~/.config
    xdg.configFile = let 
      configs = [ "chromium-flags.conf" "electron-flags.conf" ] ++ 
                (map (v: "electron-flags${toString v}.conf") (lib.range 14 40));
      value = { text = lib.concatStringsSep "\n" switches; };
    in builtins.listToAttrs (map (name: { inherit name value;  }) configs);

    # Populate ~/.config/chromium/External Extensions
    systemd.user = let
      inherit (perSystem.self) mkScript;
      extNames = builtins.attrNames (cfg.externalExtensions // cfg.unpackedExtensions);
      crxDir = osConfig.programs.chromium.crxDir;
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
          ExecStart = "${mkScript ''
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
          '' + builtins.concatStringsSep "\n" ( 
            map (name: "symlink ${name}") extNames 
          ) + ''

            # Disable nullglob again
            shopt -u nullglob
          ''}";
          Restart = "no";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };

      # Watch persistent storage for updates
      paths.crx = {
        Unit.Description = "Symlink chromium extentions";
        Path = {
          PathChanged = "${crxDir}/last";
          Unit = "crx.service";
        };
        Install.WantedBy = [ "default.target" ];
      };

    };

  };

}
