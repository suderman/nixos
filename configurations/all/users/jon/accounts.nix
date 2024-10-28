{ config, lib, pkgs, this, ... }: let 

  cfg = config.accounts;
  inherit (lib) mkIf mkShellScript;

in {

  config = mkIf cfg.enable {

    # Passwords for accounts
    age.secrets = let inherit (config.home) username; in {
      fastmail.file = config.secrets.files."password-${username}-fastmail";
      icloud.file = config.secrets.files."password-${username}-icloud";
      gmail.file = config.secrets.files."password-${username}-gmail";
    };

    # Configure email/calendar/contacts accounts
    # https://home-manager-options.extranix.com/?query=accounts.&release=master
    accounts = let 

      # Get account password: pass fastmail|icloud|gmail
      pass = mkShellScript { text = ''
        case "$@" in
          fastmail) cat ${config.age.secrets.fastmail.path};;
          icloud) cat ${config.age.secrets.icloud.path};;
          gmail) cat ${config.age.secrets.gmail.path};;
        esac
      ''; };

    in {

      # Calendars are stored at ~/Calendars
      calendar = {
        basePath = "Calendars";
        accounts."Fastmail" = {
          primary = true;
          primaryCollection = "Family";
          local = {
            fileExt = ".ics";
            type = "filesystem";
          };
          remote = {
            userName = "suderman@fastmail.com";
            passwordCommand = [ "bash" "${pass}" "fastmail" ];
            url = "https://caldav.fastmail.com/";
            type = "caldav";
          };
          khal = {
            enable = true;
            type = "discover"; # calendar, birthdays, discover
            priority = 1000;
            color = "#ff0000";
          };
          qcal.enable = true; # trying out
          vdirsyncer = {
            enable = true;
            collections = [ "from a" "from b" ];
            metadata = [ "color" "displayname" ];
            # itemTypes = [ "VEVENT" ];
            # timeRange = {
            #   start = "datetime.now() - timedelta(days=7)";
            #   end = "datetime.now() + timedelta(days=30)";
            # };
          };
        };
      };

      # Email is stored at ~/Mail
      email.maildirBasePath = "Mail";

      # Personal email
      email.accounts."Fastmail" = rec {
        userName = "suderman@fastmail.com";
        passwordCommand = [ "bash" "${pass}" "fastmail" ];
        flavor = "fastmail.com";
        primary = true;
        realName = "Jon Suderman";
        address = "jon@suderman.net";
        folders = {
          inbox = "Inbox";
          drafts = "Drafts";
          sent = "Sent";
          trash = "Trash";
        };
        signature = {
          showSignature = "append";
          text = ''
            ${realName}
            https://suderman.net
          '';
        };
        mbsync = {
          enable = true;
          create = "maildir";
          expunge = "both";
        };
        neomutt = {
          enable = true;
          extraMailboxes = [ "Archive" "Drafts" "Sent" "Trash" ];
        };
        notmuch.enable = true;
        msmtp.enable = true;
      };

      # Work email
      email.accounts."Gmail" = rec {
        userName = "jon@nonfiction.ca";
        passwordCommand = [ "bash" "${pass}" "gmail" ];
        flavor = "gmail.com";
        realName = "Jon Suderman";
        address = "jon@nonfiction.ca";
        folders = {
          inbox = "Inbox";
          drafts = "Drafts";
          sent = "Sent";
          trash = "Trash";
        };
        signature = {
          showSignature = "append";
          text = ''
            ${realName}
            https://nonfiction.ca
          '';
        };
        mbsync = {
          enable = true;
          create = "maildir";
          expunge = "both";
        };
        neomutt = {
          enable = true;
          extraMailboxes = [ "Archive" "Drafts" "Sent" "Trash" ];
        };
        notmuch.enable = true;
        msmtp.enable = true;
      };

    };

    # Email reader
    programs.neomutt.enable = true;

    # IMAP sync
    programs.mbsync.enable = true;

    # SMTP client
    programs.msmtp.enable = true; # neomutt will send via msmtp by default if enable

    # Email indexer
    programs.notmuch = {
      enable = true;
      # hooks.preNew = "mbsync --all"; 
    };

    # DAV sync
    programs.vdirsyncer.enable = true;

    programs.qcal.enable = true;
    programs.khal = {
      enable = true;
      settings = {
        # default.default_calendar = "Family";
        default.default_event_duration = "30m";
      };
    };

    # Address book
    programs.khard = {
      enable = true;
      settings = {
        general.default_action = "list";
      };
    };

  };

}
