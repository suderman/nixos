{ config, lib, pkgs, this, ... }: let 

  cfg = config.accounts;
  inherit (lib) mkIf mkShellScript;

  fastmail = {
    userName = "suderman@fastmail.com";
    passwordCommand = [ "cat" "${config.age.secrets.fastmail.path}" ];
  };

  gmail = {
    userName = "jon@nonfiction.ca";
    passwordCommand = [ "cat" "${config.age.secrets.gmail.path}" ];
  };

in {

  config = mkIf cfg.enable {

    # Passwords for accounts
    age.secrets.fastmail.file = config.secrets.files.password-jon-fastmail;
    age.secrets.gmail.file = config.secrets.files.password-jon-gmail;

    accounts.contact = {
      basePath = "Contacts";
      accounts."Fastmail" = {
        local = {
          type = "filesystem";
          fileExt = ".vcf";
        };
        remote = fastmail // {
          url = "https://carddav.fastmail.com/";
          type = "carddav";
        };
        khard.enable = true;
        vdirsyncer.enable = true;
      };
    };

    accounts.calendar = {
      basePath = "Calendars";
      accounts."Fastmail" = {
        primary = true;
        # name = "suderman";
        local = {
          fileExt = ".ics";
          type = "filesystem";
        };
        remote = fastmail // {
          url = "https://caldav.fastmail.com/";
          type = "caldav";
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
    accounts.email.accounts."Fastmail" = fastmail // rec {
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
    accounts.email.accounts."Gmail" = gmail // rec {
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
