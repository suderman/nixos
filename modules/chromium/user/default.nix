# programs.chromium.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.chromium;
  inherit (lib) ls mkIf mkOption types;
  inherit (config.services.keyd.lib) mkClass;
  inherit (config.programs.chromium.lib) switches browserSwitches unpackedExtensions;

  # Window class name
  class = "chromium-browser";

in {

  # import chromium lib
  imports = ls ./.;

  # extra options to manage unpacked extensions
  options.programs.chromium = {

    # Extensions to automatically download and include with --load-extension
    unpackedExtensions = mkOption {
      type = types.anything; 
      default = {};
    };

    # Where to download to and load extensions from
    unpackedExtensionsDir = mkOption {
      type = types.path; 
      default = "${config.xdg.dataHome}/chromium/extensions";
    };
  };

  config = mkIf cfg.enable {

    # using Chromium without Google
    programs.chromium = {
      package = pkgs.ungoogled-chromium;
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

    # Download and keep chromium extensions up-to-date
    systemd.user = let

      inherit (lib) mkShellScript;
      inherit (builtins) attrNames concatStringsSep;
      inherit (lib) hasPrefix mapAttrsToList versions;

      url = id: if hasPrefix "http://" id || hasPrefix "https://" id then id else 
        "https://clients2.google.com/service/update2/crx" +
        "?response=redirect" +
        "&acceptformat=crx2,crx3" +
        "&prodversion=${versions.major cfg.package.version}" + 
        "&x=id%3D${id}%26installsource%3Dondemand%26uc";

    in {
      services.chromium-download-extensions = {
        Unit.Description = "Download chromium exentions";
        Unit.After = [ "network-online.target" ];
        Unit.Wants = [ "network-online.target" ];
        Service.Type = "oneshot";
        Service.ExecStart = mkShellScript {
          inputs = [ pkgs.curl pkgs.zip ];
          text = ''

            # Create and move to extensions directory
            mkdir -p ${cfg.unpackedExtensionsDir}
            cd ${cfg.unpackedExtensionsDir}

            # Ensure the extension directories exists with stub manifest to avoid errors
            for dir in ${toString (attrNames unpackedExtensions)}; do
              if [[ ! -d $dir ]]; then
                mkdir $dir
                echo "{ \"manifest_version\": 3, \"name\": \"$dir\", \"version\": \"0.0.1\" }" > $dir/manifest.json
                touch -d '2000-01-01 00:00:00' $dir/manifest.json
              fi
            done

          '' + concatStringsSep "\n" (mapAttrsToList ( name: id: ''
            # Attempt to download the ${name} extension
            curl -L "${url id}" > ${name}.zip || true

            # If successful, unzip contents into extension's directory
            if [[ -f ${name}.zip && -s ${name}.zip ]]; then
              unzip -ou ${name}.zip -d ${name} 2>/dev/null || true
            fi
          '' ) unpackedExtensions);
        };
        Install.WantedBy = [ "default.target" ];
      };

      timers.chromium-download-extensions = {
        Unit.Description = "Download chromium exentions every 6 hours";
        Timer = {
          OnBootSec = "1min";
          OnUnitActiveSec = "6h";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };

    };

  };

}
