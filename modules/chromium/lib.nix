{ config, lib, pkgs, ... }: let

  cfg = config.programs.chromium;
  inherit (builtins) isString;
  inherit (lib) getExe mkOption removePrefix removeSuffix replaceStrings toLower types;

  # Create window class name from URL used by Chromium Web Apps 
  # without slugify: https://example.com --> chrome-example.com__-Default
  #    with slugify: https://example.com --> chrome-example-com-default
  mkClass = arg: let
    toSlug = str: replaceStrings ["." "_" "/"] ["-" "" ""] (toLower str);
    toClass = { url, slugify ? false }: let 
      removeProtocols = url: removePrefix "http://" (removePrefix "https://" url);
      removeSlashes = url: replaceStrings [ "/" ] [ "." ] (removeSuffix "/" url);
      class = "chrome-${removeSlashes( removeProtocols url )}__-Default";
    in if slugify == true then (toSlug class) else class;
  in if isString arg then toClass { url = arg; slugify = true; } else toClass arg;


  # Create web app as desktop entry
  # config.xdg.desktopEntries = mkWebApp { name = "Example"; url = "https://example.com/"; };
  mkWebApp = { 
    name, url, icon ? "internet-web-browser", 
    platform ? "wayland", # x11 or wayland (wayland glitchy when resizing in hyprland)
    class ? (mkClass { inherit url; slugify = false; }) # chrome-example.com__-Default
  }: {
    "${class}" = {
      inherit name icon;
      exec = "${getExe pkgs.chromium} " + toString [ 
        ''--ozone-platform-hint="${platform}"''
        ''--class="${class}"''
        ''--user-data-dir=".local/share/webapps/${class}"''
        ''--app="${url}"''
        "%U"
      ];
    };

  };

in {

  options.programs.chromium.lib = mkOption {
    type = types.anything; 
    readOnly = true; 
    default = { inherit mkClass mkWebApp; };
  };

}
