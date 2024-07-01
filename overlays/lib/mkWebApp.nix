{ pkgs, lib, this, ... }: let

  inherit (lib) mkIf getExe replaceStrings removePrefix removeSuffix;
  inherit (builtins) toString;
  toClass = url: replaceStrings ["/"] ["."] (removeSuffix "/" ( removePrefix "http://" (removePrefix "https://" url) ));

in { name, url, icon ? "internet-web-browser", platform ? "x11", class ? toClass url }: {

  "chrome-${class}__-Default" = {
    inherit name icon;
    exec = "${getExe pkgs.chromium} " + toString [ 
      "--ozone-platform-hint=${platform}" # x11 or wayland (wayland glitchy on nvidia until explicit sync available)
      "--class=chrome-${class}__-Default"
      "--user-data-dir=\"\\\\$HOME/.local/share/webapps/${class}\""
      "--app=${url}"
      "%U"
    ];
  };

}

