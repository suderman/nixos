{ config, osConfig, lib, pkgs, ... }: let

  cfg = config.programs.chromium;
  oscfg = osConfig.programs.chromium;
  inherit (builtins) attrNames;
  inherit (lib) concatStringsSep mkOption types;

  # Add these switches to the wrapper or config
  switches = let

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
      "WaylandLinuxDrmSyncobj"  #wayland-linux-drm-syncobj (min kernel v6.11)
      "WaylandPerSurfaceScale"  #wayland-per-window-scaling
      "WaylandTextInputV3"      #wayland-text-input-v3
      "WaylandUiScale"          #wayland-ui-scaling
      "WebRTCPipeWireCapturer"
      "WebUIDarkMode"
    ];

  # Used in webapps and browser
  in [
    "--disable-features=EnableTabMuting"
    "--disable-top-sites" # (relates to the browser's new tab page)
    "--enable-accelerated-video-decode"
    "--enable-features=${features}"
    "--enable-gpu-rasterization"
    "--enable-incognito-themes" # (browser's incognito mode)
    "--extension-mime-request-handling=always-prompt-for-install" # (browser extension handling)
    "--fingerprinting-canvas-image-data-noise" # (browser-specific privacy feature)
    "--fingerprinting-canvas-measuretext-noise" # (browser-specific privacy feature)
    "--fingerprinting-client-rects-noise" # (browser-specific privacy feature)
    "--load-extension=${unpackedExtensionsDirs}" # (browser extension loading)
    "--no-default-browser-check"
    "--ozone-platform=wayland"
    "--remove-referrers" # (browser privacy feature)
  ];

  # Create window class name from URL used by Chromium Web Apps 
  # without keydify: https://example.com --> chrome-example.com__-Default
  #    with keydify: https://example.com --> chrome-example-com-default
 mkClass = arg: let
    inherit (builtins) isString;
    inherit (lib) removePrefix removeSuffix replaceStrings;
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
    name, url, icon ? "internet-web-browser", profile ? null,
    class ? (mkClass { inherit url; keydify = false; }) # chrome-example.com__-Default
  }: let 
    dataDir = if isNull profile then cfg.dataDir else "${cfg.dataDir}/profiles/${profile}";
    runDir = if isNull profile then "${cfg.runDir}/default" else "${cfg.runDir}/${profile}";
  in {
    "${class}" = {
      inherit name icon;
      exec = "${lib.getExe cfg.package} " + toString (switches ++ [ 
        ''--user-data-dir="${dataDir}"''
        ''--disk-cache-dir="${runDir}"''
        ''--class="${class}"''
        ''--app="${url}"''
        "%U"
      ]);
    };
  };

in {

  options.programs.chromium.lib = mkOption {
    type = types.anything; 
    default = { inherit mkClass mkWebApp switches; };
    readOnly = true; 
  };

}
