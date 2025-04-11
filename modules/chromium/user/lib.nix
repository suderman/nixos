{ config, lib, pkgs, ... }: let

  cfg = config.programs.chromium;
  inherit (builtins) attrNames isString;
  inherit (lib) concatStringsSep getExe mkOption removePrefix removeSuffix replaceStrings toLower types;

  # Always load chromium web store
  unpackedExtensions = cfg.unpackedExtensions // {
    chromium-web-store = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.4.3/Chromium.Web.Store.crx";
  };

  # Store cache on volatile disk
  runDir = "/run/user/${toString config.home.uid}/chromium-cache";

  # Store profile in ~/.local/share/chromium
  dataDir = "${config.xdg.dataHome}/chromium/profile";

  # Convert extension names to comma-separated directories
  extensionsDirs = concatStringsSep "," (
    map (dir: "${cfg.unpackedExtensionsDir}/${dir}") (attrNames unpackedExtensions)
  );

  # Enable these features in chromium
  features = concatStringsSep "," [
    "DevToolsPrivacyUI"
    "EnableFingerprintingProtectionFilter:activation_level/enabled/enable_console_logging/true"
    "EnableFingerprintingProtectionFilterInIncognito:activation_level/enabled/enable_console_logging/true"
    "ImprovedSettingsUIOnDesktop"
    "MultiTabOrganization"
    "OneTimePermission"
    "TabOrganization"
    "TabOrganizationSettingsVisibility"
    "TabReorganization"
    "TabReorganizationDivider"
    "TabSearchPositionSetting"
    "TabstripDeclutter"
    "TabstripDedupe"
    "TaskManagerDesktopRefresh"
    "UseOzonePlatform"
    "WaylandLinuxDrmSyncobj"  #wayland-linux-drm-syncobj
    "WaylandPerSurfaceScale"  #wayland-per-window-scaling
    "WaylandTextInputV3"      #wayland-text-input-v3
    "WaylandUiScale"          #wayland-ui-scaling
    "WebRTCPipeWireCapturer"
    "WebUIDarkMode"
  ];

  # Add these switches to the wrapper or config
  switches = [ 
    "--disable-features=EnableTabMuting"
    "--disk-cache-dir=${runDir}"
    "--user-data-dir=${dataDir}"
    "--enable-accelerated-video-decode"
    "--enable-features=${features}"
    "--enable-gpu-rasterization"
    "--no-default-browser-check"
    "--ozone-platform=wayland"
  ];

  # Additional switches just for the web browser
  browserSwitches = [
    "--disable-top-sites" # (relates to the browser's new tab page)
    "--enable-incognito-themes" # (browser's incognito mode)
    "--extension-mime-request-handling=always-prompt-for-install" # (browser extension handling)
    "--fingerprinting-canvas-image-data-noise" # (browser-specific privacy feature)
    "--fingerprinting-canvas-measuretext-noise" # (browser-specific privacy feature)
    "--fingerprinting-client-rects-noise" # (browser-specific privacy feature)
    "--load-extension=${extensionsDirs}" # (browser extension loading)
    "--remove-referrers" # (browser privacy feature)
  ];

  # Create window class name from URL used by Chromium Web Apps 
  # without keydify: https://example.com --> chrome-example.com__-Default
  #    with keydify: https://example.com --> chrome-example-com-default
  mkClass = arg: let
    toKeydClass = config.services.keyd.lib.mkClass;
    toClass = { url, keydify ? false }: let 
      removeProtocols = url: removePrefix "http://" (removePrefix "https://" url);
      removeSlashes = url: replaceStrings [ "/" ] [ "." ] (removeSuffix "/" url);
      class = "chrome-${removeSlashes( removeProtocols url )}__-Default";
    in if keydify == true then (toKeydClass class) else class;
  in if isString arg then toClass { url = arg; keydify = true; } else toClass arg;


  # Create web app as desktop entry
  # config.xdg.desktopEntries = mkWebApp { name = "Example"; url = "https://example.com/"; };
  mkWebApp = { 
    name, url, icon ? "internet-web-browser", 
    platform ? "wayland", # x11 or wayland (wayland glitchy when resizing in hyprland)
    class ? (mkClass { inherit url; keydify = false; }) # chrome-example.com__-Default
  }: {
    "${class}" = {
      inherit name icon;
      exec = "${getExe cfg.package} " + toString (switches ++ [ 
        ''--ozone-platform-hint="${platform}"''
        ''--class="${class}"''
        ''--user-data-dir="${config.xdg.dataHome}/chromium/webapps/${class}"''
        ''--app="${url}"''
        "%U"
      ]);
    };

  };

in {

  options.programs.chromium.lib = mkOption {
    type = types.anything; 
    readOnly = true; 
    default = { inherit mkClass mkWebApp switches browserSwitches unpackedExtensions; };
  };

}
