# programs.neomutt.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.neomutt;
  inherit (lib) getExe mkIf;

  # Use ungoogled-chromium as an HTML pager for mutt
  pager = rec {
    name = "Mutt Pager";
    file = "/tmp/mutt.html";
    url = "file://${file}";
    class = config.lib.chromium.mkClass {inherit url;};
    icon = "system-search";
    pipe = toString [
      "cat ${style} /dev/stdin >${file}"
      "&&"
      "chromium --app=\"${url}\""
      ">/dev/null 2>&1"
    ];
    style =
      pkgs.writeText "style.css"
      # css
      ''
        <style>
          html { font-size: 16px; }
          body {
            font-family: "${config.stylix.fonts.sansSerif.name}", Helvetica, Arial, sans-serif;
            line-height: 1.6;
            max-width: 700px;
            margin: 0 auto !important;
            padding: 2rem;
            color: #24292e;
            background: linear-gradient(to right, rgb(0 0 0 / 25%) 0%, rgba(0, 0, 0, 0.02) 5%, rgba(0, 0, 0, 0) 10%, rgba(0, 0, 0, 0) 90%, rgba(0, 0, 0, 0.02) 95%, rgba(0, 0, 0, 0.25) 100%);
          }
          h1, h2, h3, h4, h5, h6 {
            margin-top: 1.5em;
            margin-bottom: 1em;
            font-weight: 600;
            line-height: 1.25;
            border-bottom: 1px solid #d0d7de;
            padding-bottom: 0.3em;
          }
          h1 { font-size: 2em; }
          h2 { font-size: 1.5em; }
          h3 { font-size: 1.25em; }
          h4 { font-size: 1em; border-bottom: none; }
          h5, h6 { font-size: 0.875em; border-bottom: none; color: #57606a; }
          p, ul, ol { margin: 1em 0; }
          ul, ol { padding-left: 2em; }
          a { color: #0969da; text-decoration: none; }
          a:hover { text-decoration: underline; }
        </style>
      '';
  };
in {
  config = mkIf cfg.enable {
    xdg.desktopEntries = config.lib.chromium.mkWebApp {inherit (pager) name url icon;};
    programs.neomutt.macros = [
      {
        action = "<view-attachments><search>html<enter><pipe-entry>${pager.pipe}<enter><exit>";
        key = "<space>";
        map = ["index" "pager"];
      }
      {
        action = "<pipe-entry>${pager.pipe}<enter><exit>";
        key = "<space>";
        map = ["attach"];
      }
    ];
    # xdg.desktopEntries = {
    #   "neomutt" = {
    #     name = "NeoMutt";
    #     genericName = "Email Client";
    #     icon = "mutt";
    #     terminal = true;
    #     categories = ["Network" "Email" "ConsoleOnly"];
    #     type = "Application";
    #     mimeType = ["x-scheme-handler/mailto"];
    #   };
    # };

    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/mailto" = "neomutt.desktop";
    };

    wayland.windowManager.hyprland.settings.windowrule = [
      "float, class:${pager.class}"
      "size 800 900, class:${pager.class}"
      "animation gnomed, class:${pager.class}"
    ];

    services.keyd.windows."${config.lib.keyd.mkClass pager.class}" = {
      "j" = "down";
      "k" = "up";
      "equal" = "C-S-equal";
      "minus" = "C-S-minus";
      "h" = "C-w";
      "q" = "C-w";
      "esc" = "C-w";
    };
  };
}
