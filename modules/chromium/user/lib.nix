{ config, osConfig, lib, pkgs, ... }: let

  cfg = config.programs.chromium;
  oscfg = osConfig.programs.chromium;
  inherit (builtins) attrNames isString;
  inherit (lib) concatStringsSep getExe mkOption removePrefix removeSuffix replaceStrings toLower types;

  # Store cache on volatile disk
  runDir = "/run/user/${toString config.home.uid}/chromium-cache";

  # Convert extension names to comma-separated directories
  unpackedExtensionsDirs = concatStringsSep "," (
    map (name: "${oscfg.crxDir}/${name}/extension") (attrNames cfg.unpackedExtensions)
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
  switches = {

    # Common with both webapps and browser
    common = [ 
      "--disable-features=EnableTabMuting"
      "--disk-cache-dir=${runDir}"
      "--enable-accelerated-video-decode"
      "--enable-features=${features}"
      "--enable-gpu-rasterization"
      "--no-default-browser-check"
      "--ozone-platform=wayland"
    ];

    # Additional switches just for the web browser
    browser = [
      "--disable-top-sites" # (relates to the browser's new tab page)
      "--enable-incognito-themes" # (browser's incognito mode)
      "--extension-mime-request-handling=always-prompt-for-install" # (browser extension handling)
      "--fingerprinting-canvas-image-data-noise" # (browser-specific privacy feature)
      "--fingerprinting-canvas-measuretext-noise" # (browser-specific privacy feature)
      "--fingerprinting-client-rects-noise" # (browser-specific privacy feature)
      "--load-extension=${unpackedExtensionsDirs}" # (browser extension loading)
      "--remove-referrers" # (browser privacy feature)
    ];

  };

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
      exec = "${getExe cfg.package} " + toString (switches.common ++ [ 
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
    default = { inherit switches mkClass mkWebApp; };
  };

}
