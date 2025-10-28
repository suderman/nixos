# programs.neomutt.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.neomutt;
  inherit (lib) getExe hasAttr mkIf;
in {
  config = mkIf cfg.enable {
    programs.neomutt = {
      vimKeys = true;
      checkStatsInterval = 60;
      sidebar = {
        enable = true;
        width = 30;
      };
      settings = {
        mark_old = "no";
        text_flowed = "yes";
        reverse_name = "yes";
        query_command = ''"khard email --parsable '%s'"'';
        wait_key = "no";
      };
      binds = [
        {
          map = ["index" "pager"];
          key = "\\\\";
          action = "sidebar-toggle-visible";
        }
        {
          map = ["index" "pager"];
          key = "L";
          action = "group-reply";
        }
        {
          map = ["index"];
          key = "B";
          action = "toggle-new";
        }
        {
          map = ["index"];
          key = "l";
          action = "display-message";
        }
        {
          map = ["pager"];
          key = "h";
          action = "exit";
        }
        {
          map = ["index"];
          key = "h";
          action = "noop";
        }
      ];

      macros = let
        qutebrowserpipe = toString [
          "cat /dev/stdin >/tmp/mutt.html"
          "&&"
          "${pkgs.qutebrowser}/bin/qutebrowser /tmp/mutt.html"
          ">/dev/null 2>&1"
        ];
        browserpipe = toString [
          "cat /dev/stdin >/tmp/mutt.html"
          "&&"
          "chromium --app=\"file:///tmp/mutt.html\""
          ">/dev/null 2>&1"
        ];
      in [
        {
          action = "<sidebar-next><sidebar-open>";
          key = "J";
          map = ["index" "pager"];
        }
        {
          action = "<sidebar-prev><sidebar-open>";
          key = "K";
          map = ["index" "pager"];
        }
        {
          action = ":set confirmappend=no\\n<save-message>+Archive<enter>:set confirmappend=yes\\n";
          key = "A";
          map = ["index" "pager"];
        }
        # {
        #   action = "<pipe-entry>${browserpipe}<enter><exit>";
        #   key = "V";
        #   map = ["attach"];
        # }
        {
          action = "<pipe-message>${pkgs.urlscan}/bin/urlscan<enter><exit>";
          key = "F";
          map = ["pager"];
        }
        {
          action = "<view-attachments><search>html<enter><pipe-entry>${browserpipe}<enter><exit>";
          key = "V";
          map = ["index" "pager"];
        }
        {
          action = "<display-message>";
          key = "<return>";
          map = ["index"];
        }
        {
          action = "<exit>";
          key = "<return>";
          map = ["pager"];
        }
      ];
      extraConfig =
        ''
          source alternates
        ''
        + builtins.readFile ./colors.muttrc;
    };

    # If there is a secret named addresses, format that as a line of alternates for this user
    home.activation.neomutt = let
      dir = "$HOME/.config/neomutt";
      awk = getExe pkgs.gawk;
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p ${dir}
        $DRY_RUN_CMD touch ${dir}/alternates
        $DRY_RUN_CMD echo "alternates \"$(${awk} '{printf "%s%s", (NR==1 ? "" : "|"), $0} END {print ""}' ${config.age.secrets.addresses.path})\"" > ${dir}/alternates
      '';

    home.shellAliases = {
      mutt = "neomutt";
    };

    home.localStorePath = [".config/neomutt/neomuttrc"];

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

    wayland.windowManager.hyprland.settings.windowrule = let
      class = "chrome-__tmp_mutt.html-Default";
    in [
      "float, class:${class}"
      "size 650 850, class:${class}"
    ];
  };
}
