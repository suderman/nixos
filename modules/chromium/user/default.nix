# programs.chromium.enable = true;
{ config, osConfig, lib, pkgs, ... }: let

  cfg = config.programs.chromium;
  inherit (lib) mkIf mkOption types;
  inherit (config.services.keyd.lib) mkClass;
  inherit (config.programs.chromium.lib) switches browserSwitches extensions;

  # Window class name
  class = "chromium-browser";

in {

  # import chromium lib
  imports = [ ./lib.nix ./registry.nix ];

  # extra options to manage unpacked extensions
  options.programs.chromium = {

    # Extensions to automatically download and include
    externalExtensions = mkOption {
      type = types.anything; 
      default = {};
    };

    # Extensions to automatically download and include unpacked
    unpackedExtensions = mkOption {
      type = types.anything; 
      default = {};
    };

    # Registry of chromium extensions
    registry = lib.mkOption {
      type = types.anything; 
      default = {};
      example = {
        chromium-web-store = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.4.3/Chromium.Web.Store.crx";
        ublock-origin = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
      };
    };

  };

  config = mkIf cfg.enable {

    # using Chromium without Google
    programs.chromium = {
      package = osConfig.programs.chromium.package;
      dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
      commandLineArgs = switches ++ browserSwitches;  
    };

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {
      "alt.f" = "C-f"; # find in page
      "super.[" = "C-S-tab"; # prev tab
      "super.]" = "macro(C-tab)"; # next tab
      "super.w" = "C-w"; # close tab
      "super.t" = "C-t"; # new tab
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

    systemd.user = let
      inherit (lib) mkShellScript;
      inherit (builtins) attrNames concatStringsSep;
      crxDir = osConfig.programs.chromium.crxDir;
      extDir = "${config.xdg.configHome}/chromium/External Extensions";
    in {
      services.crx = {
        Unit.Description = "Symlink chromium extentions";
        Unit.After = [ "network-online.target" ];
        Unit.Wants = [ "network-online.target" ];
        Service.Type = "oneshot";
        Service.ExecStart = mkShellScript {
          text = ''
            # Ensure external extensions directory exists
            dir="${extDir}"
            mkdir -p "$dir"

            # Change dirctory and clear it out
            cd "$dir"
            rm -f *.json

            # Symlink each extension's json here
            symlink() {
              shopt -s nullglob
              for json in ${crxDir}/$1/*.json; do
                ln -sf $json .
              done
              shopt -u nullglob
            }

            # External extensions
          '' + concatStringsSep "\n" ( 
            map (name: "symlink ${name}") (attrNames extensions) 
          );
        };
        Install.WantedBy = [ "default.target" ];
      };

      paths.crx = {
        Unit.Description = "Symlink chromium extentions";
        Path = {
          PathExists = "${crxDir}/last";
          PathChanged = "${crxDir}/last";
          Unit = "crx.service";
        };
        Install.WantedBy = [ "default.target" ];
      };

    };

  };

}
