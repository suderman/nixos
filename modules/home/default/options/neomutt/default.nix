# programs.neomutt.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.programs.neomutt;
in {
  imports = flake.lib.ls ./.;

  config = lib.mkIf cfg.enable {
    programs.neomutt = {
      vimKeys = false;
      checkStatsInterval = 60;
      unmailboxes = false;
      sidebar = {
        enable = true;
        width = 30;
      };
      settings = {
        abort_key = "<Esc>";
        auto_tag = "yes";
        mark_old = "no";
        text_flowed = "yes";
        reverse_name = "yes";
        query_command = ''"khard email --parsable '%s'"'';
        wait_key = "no";
        folder = config.accounts.email.maildirBasePath;
        mailcap_path = "${config.home.homeDirectory}/.config/neomutt/mailcap";

        edit_headers = "yes"; # show headers when composing
        fast_reply = "yes"; # skip to compose when replying
        help = "no";

        menu_context = "50";
        pager_context = "7"; # still figuring out this one
        pager_index_lines = "7"; # number of lines in pager's mini index
        pager_read_delay = "0"; # number of seconds before marking as read
        pager_stop = "yes"; # prevent page-down from skipping to the next message
        markers = "no"; # supress + marker at beginning of wrapped lines
        tilde = "yes"; # pad pager lines at bottom of screen with ~
        resolve = "no"; # don't advance to the next line after toggling a message

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
      };

      extraConfig =
        # sh
        ''
          # Source email alternates from secrets
          source alternates

          # Binds and macros
          source binds

          # Colors and status line format
          source style
          source formats

          # hjkl navigation, initialize with message index
          source 1-index

          # Configure how message is viewed in pager
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
        '';
    };

    # Abort key set to Esc, so let's make this as snappy as vim
    home.sessionVariables.ESCDELAY = 25;

    # If there is a secret named addresses, format that as a line of alternates for this user
    home.activation.neomutt = let
      dir = "$HOME/.config/neomutt";
      awk = lib.getExe pkgs.gawk;
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p ${dir}
        $DRY_RUN_CMD touch ${dir}/alternates
        $DRY_RUN_CMD echo "alternates \"$(${awk} '{printf "%s%s", (NR==1 ? "" : "|"), $0} END {print ""}' ${config.age.secrets.addresses.path})\"" > ${dir}/alternates
      '';

    home.shellAliases.mutt = "neomutt";
    home.localStorePath = [".config/neomutt/neomuttrc"];
  };
}
