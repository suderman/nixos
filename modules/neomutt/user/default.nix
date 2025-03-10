# programs.neomutt.enable = true;
{ config, lib, pkgs, this, ... }: let

  cfg = config.programs.neomutt;
  inherit (lib) getExe hasAttr mkIf mkAfter;
  emails = "emails-${config.home.username}";

in {


  config = mkIf cfg.enable {

    # decrypt list of email addresses
    age.secrets.emails.file = if hasAttr emails config.secrets.files then config.secrets.files."${emails}" else null;

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
      };
      binds = [
        {
          action = "sidebar-toggle-visible";
          key = "\\\\";
          map = [ "index" "pager" ];
        }
        {
          action = "group-reply";
          key = "L";
          map = [ "index" "pager" ];
        }
        {
          action = "toggle-new";
          key = "B";
          map = [ "index" ];
        }
      ];
      macros =
        let
          qutebrowserpipe = "cat /dev/stdin > /tmp/muttmail.html && ${pkgs.qutebrowser}/bin/qutebrowser /tmp/muttmail.html";
        in
        [
          {
            action = "<sidebar-next><sidebar-open>";
            key = "J";
            map = [ "index" "pager" ];
          }
          {
            action = "<sidebar-prev><sidebar-open>";
            key = "K";
            map = [ "index" "pager" ];
          }
          {
            action = ":set confirmappend=no\\n<save-message>+Archive<enter>:set confirmappend=yes\\n";
            key = "A";
            map = [ "index" "pager" ];
          }
          {
            action = "<pipe-entry>${qutebrowserpipe}<enter><exit>";
            key = "V";
            map = [ "attach" ];
          }
          {
            action = "<pipe-message>${pkgs.urlscan}/bin/urlscan<enter><exit>";
            key = "F";
            map = [ "pager" ];
          }
          {
            action = "<view-attachments><search>html<enter><pipe-entry>${qutebrowserpipe}<enter><exit>";
            key = "V";
            map = [ "index" "pager" ];
          }
        ];
      extraConfig = ''
        source alternates
      '' + builtins.readFile ./colors.muttrc;
    };

    # If there is a secret named emails-USERNAME, format that as a line of alternates for this user
    home.activation = (if config.age.secrets.emails.file == null then {} else {
      neomutt = let dir = "$HOME/.config/neomutt"; awk = getExe pkgs.gawk; in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p ${dir}
        $DRY_RUN_CMD touch ${dir}/alternates
        $DRY_RUN_CMD echo "alternates \"$(${awk} '{printf "%s%s", (NR==1 ? "" : "|"), $0} END {print ""}' ${config.age.secrets.emails.path})\"" > ${dir}/alternates
      '';
    });

    home.shellAliases = {
      mutt="neomutt";
    };

    xdg.desktopEntries = {
      "neomutt" = {
        name = "NeoMutt"; 
        genericName = "Email Client";
        icon = "mutt"; 
        terminal = true;
        categories = [ "Network" "Email" "ConsoleOnly" ];
        type = "Application";
        mimeType = [ "x-scheme-handler/mailto" ];
      };
    };

    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/mailto" = "neomutt.desktop";
    };

  };

}
