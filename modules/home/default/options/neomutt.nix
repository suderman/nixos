# programs.neomutt.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.neomutt;
  inherit (lib) getExe mkIf;
in {
  config = mkIf cfg.enable {
    programs.neomutt = {
      vimKeys = true;
      checkStatsInterval = 60;
      unmailboxes = false;
      sidebar = {
        enable = true;
        width = 30;
      };
      settings = {
        # sidebar_visible = "no";
        abort_key = "<Esc>";
        mark_old = "no";
        text_flowed = "yes";
        reverse_name = "yes";
        query_command = ''"khard email --parsable '%s'"'';
        wait_key = "no";
        folder = config.accounts.email.maildirBasePath;
        mailcap_path = "${config.home.homeDirectory}/.config/neomutt/mailcap";

        edit_headers = "yes"; # show headers when composing
        fast_reply = "yes"; # skip to compose when replying
        forward_format = ''"Fwd: %s"''; # format of subject when forwarding
        help = "no";

        menu_context = "50";
        pager_context = "7"; # still figuring out this one
        pager_index_lines = "7"; # number of line's in pager's mini index
        pager_read_delay = "1"; # cound 1 second before marking as read
        pager_stop = "yes"; # prevent page-down from skipping to the next message
        markers = "no"; # supress + marker at beginning of wrapped lines
        tilde = "yes"; # pad pager lines at bottom of screen with ~

        status_chars = " *%A";
        status_format = ''"[ Folder: %f ] [%r%m messages%?n? (%n new)?%?d? (%d to delete)?%?t? (%t tagged)? ]%>─%?p?( %p postponed )?"'';
        date_format = ''"%d.%m.%Y %H:%M"'';
        sort = "threads";
        sort_aux = "reverse-last-date-received";
        use_threads = "threads";
        reply_regexp = ''"^(([Rr][Ee]?(\[[0-9]+\])?: *)?(\[[^]]+\] *)?)*"'';
        quote_regexp = ''"^( {0,4}[>|:#%]| {0,4}[a-z0-9]+[>|]+)+"'';
        send_charset = "utf-8:iso-8859-1:us-ascii";
        charset = "utf-8";

        mime_forward = "no";
        forward_attachments = "yes";

        menu_scroll = "yes"; # scroll menues by 1 line instead of whole page

        # The format for the pager status line.
        # default: " -%Z- %C/%m: %-20.20n   %s%*  -- (%P) "
        pager_format = "\" %C - %[%H:%M] %.20v, %s%* %?H? [%H] ?\"";
      };

      binds = [
        {
          map = ["index" "pager"];
          key = "\\\\";
          action = "sidebar-toggle-visible";
        }
        {
          map = ["index" "pager"];
          key = "R";
          action = "group-reply";
        }
        {
          map = ["index"];
          key = "B";
          action = "toggle-new";
        }
        {
          map = ["pager"];
          key = "n";
          action = "next-thread";
        }
        {
          map = ["pager"];
          key = "p";
          action = "previous-thread";
        }
        # View the raw contents of a message.
        {
          action = "view-raw-message";
          key = "Z";
          map = [
            "index"
            "pager"
          ];
        }
      ];

      macros = [
        {
          action = "<sidebar-next><sidebar-open>";
          key = "]";
          map = ["index" "pager"];
        }
        {
          action = "<sidebar-prev><sidebar-open>";
          key = "[";
          map = ["index" "pager"];
        }
        {
          action = ":set confirmappend=no\\n<save-message>+Archive<enter>:set confirmappend=yes\\n";
          key = "e";
          map = ["index" "pager"];
        }
        {
          action = "<pipe-message>${pkgs.urlscan}/bin/urlscan<enter><exit>";
          key = "U";
          map = ["pager"];
        }
      ];
      extraConfig = ''
        source alternates
        source 1-index

        auto_view = text/html text/plain text/calendar image/*
        unalternative_order text/enriched text/plain text
        alternative_order text/calendar application/ics
        alternative_order text/html text/markdown
        alternative_order text/enriched text/plain text

        # Only show the basic mail headers.
        ignore *
        unignore From To Cc Bcc Date Subject

        # Show headers in the following order.
        unhdr_order *
        hdr_order From: To: Cc: Bcc: Date: Subject:


        # ----------------------------------------------
        # Header colors:
        color header blue default ".*"
        color header brightmagenta default "^(From)"
        color header brightcyan default "^(Subject)"
        color header brightwhite default "^(CC|BCC)"

        mono bold bold
        mono underline underline
        mono indicator reverse
        mono error bold
        color normal default default
        color indicator brightblack cyan
        color sidebar_highlight brightblack cyan
        color sidebar_indicator brightblack cyan
        color sidebar_divider brightblack black
        color sidebar_flagged red black
        color sidebar_new cyan black
        color normal brightyellow default
        color error red default
        color tilde black default
        color message cyan default
        color markers red white
        color attachment white default
        color search brightmagenta default
        color status brightyellow black
        color hdrdefault brightgreen default
        color quoted green default
        color quoted1 blue default
        color quoted2 cyan default
        color quoted3 yellow default
        color quoted4 red default
        color quoted5 brightred default
        color signature brightgreen default
        color bold black default
        color underline black default
        color normal default default

        color body brightred default "[\-\.+_a-zA-Z0-9]+@[\-\.a-zA-Z0-9]+" # Email addresses
        color body brightblue default "(https?|ftp)://[\-\.,/%~_:?&=\#a-zA-Z0-9]+" # URL
        color body green default "\`[^\`]*\`" # Green text between ` and `
        color body brightblue default "^# \.*" # Headings as bold blue
        color body brightcyan default "^## \.*" # Subheadings as bold cyan
        color body brightgreen default "^### \.*" # Subsubheadings as bold green
        color body yellow default "^(\t| )*(-|\\*) \.*" # List items as yellow
        color body brightcyan default "[;:][-o][)/(|]" # emoticons
        color body brightcyan default "[;:][)(|]" # emoticons
        color body brightcyan default "[ ][*][^*]*[*][ ]?" # more emoticon?
        color body brightcyan default "[ ]?[*][^*]*[*][ ]" # more emoticon?
        color body red default "(BAD signature)"
        color body cyan default "(Good signature)"
        color body brightblack default "^gpg: Good signature .*"
        color body brightyellow default "^gpg: "
        color body brightyellow red "^gpg: BAD signature from.*"
        mono body bold "^gpg: Good signature"
        mono body bold "^gpg: BAD signature from.*"
        color body red default "([a-z][a-z0-9+-]*://(((([a-z0-9_.!~*'();:&=+$,-]|%[0-9a-f][0-9a-f])*@)?((([a-z0-9]([a-z0-9-]*[a-z0-9])?)\\.)*([a-z]([a-z0-9-]*[a-z0-9])?)\\.?|[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)(:[0-9]+)?)|([a-z0-9_.!~*'()$,;:@&=+-]|%[0-9a-f][0-9a-f])+)(/([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*(;([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*)*(/([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*(;([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*)*)*)?(\\?([a-z0-9_.!~*'();/?:@&=+$,-]|%[0-9a-f][0-9a-f])*)?(#([a-z0-9_.!~*'();/?:@&=+$,-]|%[0-9a-f][0-9a-f])*)?|(www|ftp)\\.(([a-z0-9]([a-z0-9-]*[a-z0-9])?)\\.)*([a-z]([a-z0-9-]*[a-z0-9])?)\\.?(:[0-9]+)?(/([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*(;([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*)*(/([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*(;([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*)*)*)?(\\?([-a-z0-9_.!~*'();/?:@&=+$,]|%[0-9a-f][0-9a-f])*)?(#([-a-z0-9_.!~*'();/?:@&=+$,]|%[0-9a-f][0-9a-f])*)?)[^].,:;!)? \t\r\n<>\"]"

        # Default index colors:
        color index yellow default '.*'
        color index_author red default '.*'
        color index_number blue default
        color index_subject cyan default '.*'

        # For new mail:
        color index brightyellow black "~N"
        color index_author brightred black "~N"
        color index_subject brightcyan black "~N"

        color progress black cyan
        # ----------------------------------------------

        # -- base16 colors --
        # color0  black
        # color8  black-light

        # color1  red
        # color9  red

        # color2  green
        # color10 green

        # color3  yellow
        # color11 yellow

        # color4  blue
        # color12 blue

        # color5  purple
        # color13 purple

        # color6  cyan
        # color14 cyan

        # color7  white
        # color15 white-dark

        # -- extended base16 --
        # color15 orange
        # color17 pink
        # color18 grey-dark
        # color19 grey-mid
        # color20 grey-light
        # color21 peach
      '';
    };

    # Abort key set to Esc, so let's make this as snappy as vim
    home.sessionVariables.ESCDELAY = 25;

    home.packages = [
      (pkgs.self.mkScript {
        name = "markdown";
        path = [pkgs.python3Packages.html2text pkgs.glow];
        text = ''html2text "''${1-}" | glow -'';
      })
      (pkgs.self.mkScript {
        name = "icat";
        path = [pkgs.kitty pkgs.coreutils];
        text =
          # bash
          ''
            kitty +kitten icat "$1"
            read -n 1 -s -r -p "Press any key to continue"
          '';
      })
      (pkgs.self.mkScript {
        name = "importcal";
        path = [pkgs.coreutils pkgs.unstable.rofi pkgs.khal pkgs.dunst];
        text =
          # bash
          ''
            if [[ -f $1 ]]; then
              resp=$(echo -e "yes\nno" | rofi -i -only-match -dmenu -p "Would you like to add the event:" -mesg "`khal printics -f "{title} - {start-long} → {end-long} - {location}" $1 | tail -n +2`")

              if [[ "$resp" == "yes" ]]; then
                calendar=$(echo "`khal printcalendars`" | rofi -i -only-match -dmenu -p "Save to:")
                if [ -z "$calendar" ]; then
                  exit;
                fi
                khal import -a "$calendar" --batch $1 && \
                dunstify "Calendar" "Event added to $calendar";
              fi
            fi
          '';
      })
      pkgs.zathura
      pkgs.mutt-ics
      pkgs.w3m
    ];

    home.file.".config/neomutt/0-sidebar".text =
      # sh
      ''
        unbind index h
        unbind index j
        unbind index k
        unbind index l

        bind index h sidebar-prev
        bind index j sidebar-next
        bind index k sidebar-prev
        macro index l "<sidebar-open>:source ~/.config/neomutt/1-index\n" "Index"
        color sidebar_divider brightwhite default
      '';

    home.file.".config/neomutt/1-index".text =
      # sh
      ''
        unbind index h
        unbind index j
        unbind index k
        unbind index l

        macro index h ":set sidebar_visible=yes\n:source ~/.config/neomutt/0-sidebar\n" "Sidebar"
        bind index j "next-entry"
        bind index k "previous-entry"
        macro index l "<display-message>:source ~/.config/neomutt/2-pager\n" "Pager"
        color sidebar_divider brightblack black
      '';

    home.file.".config/neomutt/2-pager".text =
      # sh
      ''
        unbind pager h
        unbind pager j
        unbind pager k
        unbind pager l

        macro pager h "<exit>:source ~/.config/neomutt/1-index\n" "Index"
        bind pager j "next-line"
        bind pager k "previous-line"
        macro pager l "<view-attachments>:source ~/.config/neomutt/3-attach\n" "Attach"
      '';

    home.file.".config/neomutt/3-attach".text =
      # sh
      ''
        unbind attach h
        unbind attach j
        unbind attach k
        unbind attach l

        macro attach h "<exit>:source ~/.config/neomutt/2-pager\n" "Pager"
        bind attach j "next-line"
        bind attach k "previous-line"
        macro attach l "<view-attach>:source ~/.config/neomutt/4-pager\n" "Attach Pager"
      '';

    home.file.".config/neomutt/4-pager".text =
      # sh
      ''
        unbind pager h
        unbind pager j
        unbind pager k
        unbind pager l

        macro pager h "<exit>:source ~/.config/neomutt/3-attach\n" "Attach"
        bind pager j "next-line"
        bind pager k "previous-line"
        bind pager l "next-line"
      '';

    home.file.".config/neomutt/mailcap".text =
      # image/*; ${pkgs.kitty}/bin/kitty +kitten icat '%s'; copiousoutput
      # text/html; html2md '%s'; copiousoutput
      # text/html; html2glow '%s'; needsterminal
      # text/html; markdown %s; copiousoutput
      # text/plain; markdown %s; copiousoutput
      # text/markdown; markdown %s; copiousoutput
      ''
        text/plain; markdown %s; copiousoutput
        text/markdown; markdown %s; copiousoutput
        text/html; w3m -I %{charset} -T text/html; copiousoutput; nametemplate=%s.html
        text/calendar; mutt-ics; copiousoutput
        application/ics; mutt-ics; copiousoutput
        image/*; icat %s
        application/pdf; zathura '%s'; test=test -n "$DISPLAY"
        application/x-pdf; zathura '%s'; test=test -n "$DISPLAY"
        application/ics; importcal '%s'; test=test -n "$DISPLAY"
        text/calendar; importcal '%s'; test=test -n "$DISPLAY"
      '';

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

    home.localStorePath = [
      ".config/neomutt/neomuttrc"
      ".config/neomutt/0-sidebar"
      ".config/neomutt/1-index"
      ".config/neomutt/2-pager"
      ".config/neomutt/3-attach"
      ".config/neomutt/4-pager"
      ".config/neomutt/mailcap"
    ];
  };
}
