{ pkgs, lib, this, ... }: let
  inherit (lib) mkIf getExe;
  inherit (this.lib) chromeClass;

in { name, url, icon ? "internet-web-browser", platform ? "x11", class ? (chromeClass { inherit url; slugify = false; }) }: {

  # chrome-example.com__-Default
  "${class}" = {
    inherit name icon;
    exec = "${getExe pkgs.chromium} " + toString [ 
      "--ozone-platform-hint=${platform}" # x11 or wayland (wayland glitchy on nvidia until explicit sync available)
      "--class=${class}"
      "--user-data-dir=\"\\\\$HOME/.local/share/webapps/${class}\""
      "--app=${url}"
      "%U"
    ];
  };

}

