# programs.chromium.enable = true;
{ config, lib, perSystem, pkgs, ... }: let

  cfg = config.programs.chromium;
  inherit (lib) ls mkIf mkOption types;
  inherit (config.services.keyd.lib) mkClass;

  # Window class name
  class = "chromium-browser";

  # Always load chromium web store
  extensions = cfg.unpackedExtensions // {
    chromium-web-store = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.4.3/Chromium.Web.Store.crx";
    # ublock-origin = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
    # dark-reader = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
  };

in {

  imports = ls ./.;

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

    programs.chromium = let 

      # Store cache on volatile disk
      runDir = "/run/user/${toString config.home.uid}/chromium-cache";

      # Convert extension names to comma-separated directories
      extensionsDirs = lib.concatStringsSep "," (
        map (dir: "${cfg.unpackedExtensionsDir}/${dir}") (builtins.attrNames extensions)
      );

      # Enable these features in chromium
      features = lib.concatStringsSep "," [
        "UseOzonePlatform"
        "WebUIDarkMode"
        "WaylandWindowDecorations"
        "WebRTCPipeWireCapturer"
        "WaylandDrmSyncobj"
      ];

    in {

      # Using Chromium without Google
      package = pkgs.ungoogled-chromium;
      dictionaries = [ pkgs.hunspellDictsChromium.en_US ];

      # Add these flags to the launcher
      commandLineArgs = [ 
        "--ozone-platform=wayland"
        "--enable-features=${features}"
        "--enable-accelerated-video-decode"
        "--enable-gpu-rasterization"
        "--remove-referrers"
        "--disable-top-sites"
        "--no-default-browser-check"
        "--disk-cache-dir=${runDir}"
        "--load-extension=${extensionsDirs}"
      ];

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

    # xdg.configFile = let flags = ''
    #     --ozone-platform=wayland
    #     --enable-features=UseOzonePlatform,WebUIDarkMode,WaylandWindowDecorations,WebRTCPipeWireCapturer,WaylandDrmSyncobj
    #     --enable-accelerated-video-decode
    #     --enable-gpu-rasterization
    #     --disk-cache-dir=/run/user/${toString config.home.uid}/chromium-cache
    #   '';
    # in {
    #   "chromium-flags.conf".text = flags;
    #   "electron-flags.conf".text = flags;
    #   "electron-flags16.conf".text = flags;
    #   "electron-flags17.conf".text = flags;
    #   "electron-flags18.conf".text = flags;
    #   "electron-flags19.conf".text = flags;
    #   "electron-flags20.conf".text = flags;
    #   "electron-flags21.conf".text = flags;
    #   "electron-flags22.conf".text = flags;
    #   "electron-flags23.conf".text = flags;
    #   "electron-flags24.conf".text = flags;
    #   "electron-flags25.conf".text = flags;
    #   "electron-flags26.conf".text = flags;
    #   "electron-flags27.conf".text = flags;
    #   "electron-flags28.conf".text = flags;
    #   "electron-flags29.conf".text = flags;
    #   "electron-flags30.conf".text = flags;
    # };

    # Download and keep chromium extensions up-to-date
    systemd.user = let

      inherit (builtins) attrNames concatStringsSep;
      inherit (lib) hasPrefix mapAttrsToList versions;
      inherit (perSystem.self) mkScript;

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
        Service.ExecStart = mkScript {
          path = [ pkgs.curl pkgs.zip ];
          text = ''

            # Create and move to extensions directory
            mkdir -p ${cfg.unpackedExtensionsDir}
            cd ${cfg.unpackedExtensionsDir}

            # Ensure the extension directories exists with stub manifest to avoid errors
            for dir in ${toString (attrNames extensions)}; do
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
          '' ) extensions);
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
