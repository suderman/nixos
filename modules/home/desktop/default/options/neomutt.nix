# programs.neomutt.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.neomutt;
  inherit (lib) getExe mkIf;

  preview = "/tmp/mutt.html";
  class = config.lib.chromium.mkClass {url = "file://${preview}";};

  browserpipe = toString [
    "cat /dev/stdin >${preview}"
    "&&"
    "chromium --app=\"file://${preview}\""
    ">/dev/null 2>&1"
  ];
in {
  config = mkIf cfg.enable {
    programs.neomutt.macros = [
      {
        action = "<view-attachments><search>html<enter><pipe-entry>${browserpipe}<enter><exit>";
        key = "o";
        map = ["index" "pager"];
      }
      {
        action = "<pipe-entry>${browserpipe}<enter><exit>";
        key = "o";
        map = ["attach"];
      }
    ];
    xdg.desktopEntries = {
      "neomutt" = {
        name = "NeoMutt";
        genericName = "Email Client";
        icon = "mutt";
        terminal = true;
        categories = ["Network" "Email" "ConsoleOnly"];
        type = "Application";
        mimeType = ["x-scheme-handler/mailto"];
      };
    };

    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/mailto" = "neomutt.desktop";
    };

    wayland.windowManager.hyprland.settings.windowrule = [
      "float, class:${class}"
      "size 650 850, class:${class}"
    ];

    services.keyd.windows."${config.lib.keyd.mkClass class}" = {
      "h" = "left";
      "j" = "down";
      "k" = "up";
      "l" = "right";
      "equal" = "C-S-equal";
      "minus" = "C-S-minus";
      "q" = "C-w";
      "esc" = "C-w";
    };
  };
}
