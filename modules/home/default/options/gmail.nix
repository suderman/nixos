# programs.gmail.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.gmail;
  inherit (lib) mkIf mkOption options types;
  inherit (config.programs.chromium.lib) mkClass mkWebApp;
in {
  options.programs.gmail = {
    enable = options.mkEnableOption "gmail";
    url = mkOption {
      type = types.str;
      default = "https://mail.google.com/";
    };
    profile = mkOption {
      type = with lib.types; nullOr str;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    services.keyd.windows = {
      "${mkClass cfg.url}" = {
        "super.[" = "A-left"; # back
        "super.]" = "A-right"; # forward
      };
    };
    xdg.desktopEntries = mkWebApp {
      name = "Gmail";
      inherit (cfg) url profile;
      icon =
        pkgs.writeText "icon.svg"
        # html
        ''
          <svg xmlns="http://www.w3.org/2000/svg" width="2500" height="1809" image-rendering="optimizeQuality" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" viewBox="7.086 7.087 1277.149 924.008"><path fill="none" d="M1138.734 931.095h.283m0 0h-.283"/><path fill="#e75a4d" d="M1179.439 7.087c57.543 0 104.627 47.083 104.627 104.626v30.331l-145.36 103.833-494.873 340.894L148.96 242.419v688.676h-37.247c-57.543 0-104.627-47.082-104.627-104.625V111.742C7.086 54.198 54.17 7.115 111.713 7.115l532.12 394.525L1179.41 7.115l.029-.028z"/><linearGradient id="a" x1="1959.712" x2="26066.213" y1="737.107" y2="737.107" gradientTransform="matrix(.0283 0 0 -.0283 248.36 225.244)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#f8f6ef"/><stop offset="1" stop-color="#e7e4d6"/></linearGradient><path fill="url(#a)" d="m111.713 7.087 532.12 394.525L1179.439 7.087z"/><path fill="#e7e4d7" d="M148.96 242.419v688.676h989.774V245.877L643.833 586.771z"/><path fill="#b8b7ae" d="m148.96 931.095 494.873-344.324-2.24-1.586L148.96 923.527z"/><path fill="#b7b6ad" d="m1138.734 245.877.283 685.218-495.184-344.324z"/><path fill="#b2392f" d="m1284.066 142.044.17 684.51c-2.494 76.082-35.461 103.238-145.219 104.514l-.283-685.219 145.36-103.833-.028.028z"/><linearGradient id="b" x1="1959.712" x2="26066.213" y1="737.107" y2="737.107" gradientTransform="matrix(.0283 0 0 -.0283 248.36 225.244)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#f8f6ef"/><stop offset="1" stop-color="#e7e4d6"/></linearGradient><path fill="url(#b)" d="m111.713 7.087 532.12 394.525L1179.439 7.087z"/><linearGradient id="c" x1="1959.712" x2="26066.213" y1="737.107" y2="737.107" gradientTransform="matrix(.0283 0 0 -.0283 248.36 225.244)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#f8f6ef"/><stop offset="1" stop-color="#e7e4d6"/></linearGradient><path fill="url(#c)" d="m111.713 7.087 532.12 394.525L1179.439 7.087z"/><linearGradient id="d" x1="1959.712" x2="26066.213" y1="737.107" y2="737.107" gradientTransform="matrix(.0283 0 0 -.0283 248.36 225.244)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#f8f6ef"/><stop offset="1" stop-color="#e7e4d6"/></linearGradient><path fill="url(#d)" d="m111.713 7.087 532.12 394.525L1179.439 7.087z"/><linearGradient id="e" x1="1959.712" x2="26066.213" y1="737.107" y2="737.107" gradientTransform="matrix(.0283 0 0 -.0283 248.36 225.244)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#f8f6ef"/><stop offset="1" stop-color="#e7e4d6"/></linearGradient><path fill="url(#e)" d="m111.713 7.087 532.12 394.525L1179.439 7.087z"/><linearGradient id="f" x1="1959.712" x2="26066.213" y1="737.107" y2="737.107" gradientTransform="matrix(.0283 0 0 -.0283 248.36 225.244)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#f8f6ef"/><stop offset="1" stop-color="#e7e4d6"/></linearGradient><path fill="url(#f)" d="m111.713 7.087 532.12 394.525L1179.439 7.087z"/><linearGradient id="g" x1="1959.712" x2="26066.213" y1="737.107" y2="737.107" gradientTransform="matrix(.0283 0 0 -.0283 248.36 225.244)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#f8f6ef"/><stop offset="1" stop-color="#e7e4d6"/></linearGradient><path fill="url(#g)" d="m111.713 7.087 532.12 394.525L1179.439 7.087z"/><linearGradient id="h" x1="1959.712" x2="26066.213" y1="737.107" y2="737.107" gradientTransform="matrix(.0283 0 0 -.0283 248.36 225.244)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#f8f6ef"/><stop offset="1" stop-color="#e7e4d6"/></linearGradient><path fill="url(#h)" d="m111.713 7.087 532.12 394.525L1179.439 7.087z"/><path fill="#f7f5ed" d="m111.713 7.087 532.12 394.525L1179.439 7.087z"/></svg>
        '';
    };
  };
}
