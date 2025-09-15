{lib, ...}: let
  inherit (lib) mkDefault;
in {
  programs.mpv = {
    enable = true;
    config = {
      background = mkDefault "color";
      hwdec = "auto";
      hwdec-codecs = "all";
    };
    bindings = {
      h = "seek -10";
      j = "add volume -2";
      k = "add volume 2";
      l = "seek 10";
      "Ctrl+l" = "ab-loop";
    };
  };
}
