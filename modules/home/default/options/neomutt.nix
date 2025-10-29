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
          map = ["attach"];
          key = "l";
          action = "view-attach";
        }
        {
          map = ["pager" "attach"];
          key = "h";
          action = "exit";
        }
        {
          map = ["pager"];
          key = "l";
          action = "view-attachments";
        }
        {
          map = ["index"];
          key = "h";
          action = "noop";
        }
      ];

      macros = [
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
        {
          action = "<pipe-message>${pkgs.urlscan}/bin/urlscan<enter><exit>";
          key = "F";
          map = ["pager"];
        }
      ];
      extraConfig = ''
        source alternates

        color normal		  default default         # Text is "Text"
        color index		    color2 default ~N       # New Messages are Green
        color index		    color1 default ~F       # Flagged messages are Red
        color index		    color13 default ~T      # Tagged Messages are Red
        color index		    color1 default ~D       # Messages to delete are Red
        color attachment	color5 default          # Attachments are Pink
        color signature	  color8 default          # Signatures are Surface 2
        color search		  color4 default          # Highlighted results are Blue

        color indicator		default color8          # currently highlighted message Surface 2=Background Text=Foreground
        color error		    color1 default          # error messages are Red
        color status		  color15 default         # status line "Subtext 0"
        color tree        color15 default         # thread tree arrows Subtext 0
        color tilde       color15 default         # blank line padding Subtext 0

        color hdrdefault  color13 default         # default headers Pink
        color header		  color13 default "^From:"
        color header	 	  color13 default "^Subject:"

        color quoted		  color15 default         # Subtext 0
        color quoted1		  color7 default          # Subtext 1
        color quoted2		  color8 default          # Surface 2
        color quoted3		  color0 default          # Surface 1
        color quoted4		  color0 default
        color quoted5		  color0 default

        color body		color2 default		[\-\.+_a-zA-Z0-9]+@[\-\.a-zA-Z0-9]+               # email addresses Green
        color body	  color2 default		(https?|ftp)://[\-\.,/%~_:?&=\#a-zA-Z0-9]+        # URLs Green
        color body		color4 default		(^|[[:space:]])\\*[^[:space:]]+\\*([[:space:]]|$) # *bold* text Blue
        color body		color4 default		(^|[[:space:]])_[^[:space:]]+_([[:space:]]|$)     # _underlined_ text Blue
        color body		color4 default		(^|[[:space:]])/[^[:space:]]+/([[:space:]]|$)     # /italic/ text Blue

        color sidebar_flagged   color1 default    # Mailboxes with flagged mails are Red
        color sidebar_new       color10 default   # Mailboxes with new mail are Green
      '';
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
  };
}
