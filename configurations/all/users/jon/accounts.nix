{ config, lib, pkgs, this, ... }: let 

  cfg = config.accounts;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # Passwords for accounts
    age.secrets.fastmail-env.file = config.secrets.files.fastmail-env;
    age.secrets.gmail-env.file = config.secrets.files.gmail-env;


    accounts.contact = {
      basePath = "Contacts";
      accounts."suderman" = {
        local = {
          type = "filesystem";
          fileExt = ".vcf";
        };
        remote = {
          url = "https://carddav.fastmail.com/";
          type = "carddav";
          userName = "suderman@fastmail.com";
          passwordCommand = "source ${config.age.secrets.fastmail-env.path} && echo $PASSWORD";
        };
        khard.enable = true;
        vdirsyncer.enable = true;
      };
    };

    accounts.calendar = {
      basePath = "Calendars";
      accounts."suderman" = {
        primary = true;
        # name = "suderman";
        local = {
          fileExt = ".ics";
          type = "filesystem";
        };
        remote = {
          url = "https://caldav.fastmail.com/";
          type = "caldav";
          userName = "suderman@fastmail.com";
          passwordCommand = "source ${config.age.secrets.fastmail-env.path} && echo $PASSWORD";
        };
        khal.enable = true;
        vdirsyncer = {
          enable = true;
          collections = [ "calendar" ];
          itemTypes = [ "VEVENT" ];
          timeRange = {
            start = "datetime.now() - timedelta(days=7)";
            end = "datetime.now() + timedelta(days=30)";
          };
        };
      };
    };

    # Email is stored at ~/Mail
    accounts.email.maildirBasePath = "Mail";

    # Personal email
    accounts.email.accounts."suderman" = rec {
      flavor = "fastmail.com";
      primary = true;
      realName = "Jon Suderman";
      address = "jon@suderman.net";
      userName = "suderman@fastmail.com";
      passwordCommand = "source ${config.age.secrets.fastmail-env.path} && echo $PASSWORD";
      folders = {
        inbox = "Inbox";
        drafts = "Drafts";
        sent = "Sent";
        trash = "Trash";
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
      signature = {
        showSignature = "append";
        text = ''
            ${realName}
            https://suderman.net
        '';
      };
    };

    # Work email
    accounts.email.accounts."nonfiction" = rec {
      flavor = "gmail.com";
      realName = "Jon Suderman";
      address = "jon@nonfiction.ca";
      userName = address;
      passwordCommand = "source ${config.age.secrets.gmail-env.path} && echo $PASSWORD";
      folders = {
        inbox = "Inbox";
        drafts = "Drafts";
        sent = "Sent";
        trash = "Trash";
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
      signature = {
        showSignature = "append";
        text = ''
          ${realName}
          https://nonfiction.ca
        '';
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

    # Address book
    programs.khard = {
      enable = true;
      settings = {
        general.default_action = "list";
      };
    };

  };

}
