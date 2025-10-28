{
  config,
  lib,
  pkgs,
  ...
}: let
  # Persist this directory
  dataDir = ".local/share/accounts";

  # Get account password: pass fastmail|icloud|gmail
  pass = pkgs.self.mkScript {
    text = ''
      case "$@" in
        fastmail) cat ${config.age.secrets.fastmail.path};;
        icloud) cat ${config.age.secrets.icloud.path};;
        gmail) cat ${config.age.secrets.gmail.path};;
      esac
    '';
  };
  # yes | vdirsyncer discover
  # vdirsyncer sync
  # vdirsyncer discover calendar_calendars
  # vdirsyncer discover contacts_contacts
in {
  config = lib.mkIf config.accounts.enable {
    # Persist account data
    persist.storage.directories = [dataDir];

    # Passwords for accounts
    age.secrets.fastmail.rekeyFile = ./password-fastmail.age;
    age.secrets.gmail.rekeyFile = ./password-gmail.age;
    age.secrets.icloud.rekeyFile = ./password-icloud.age;

    # Email addresses I've used
    age.secrets.addresses.rekeyFile = ./addresses.age;

    # Configure email/calendar/contacts accounts
    # https://home-manager-options.extranix.com/?query=accounts.&release=master
    # I've configured Fastmail to syncronize shared calendars from iCloud & Gmail.
    # This way, I only need to configure the below calendars to talk to Fastmail
    # to sync with my computers.
    accounts = {
      # Calendars are stored at ~/.local/share/accounts/calendars
      calendar = {
        basePath = dataDir;
        accounts."calendars" = {
          primary = true;
          primaryCollection = "Personal";
          remote = {
            userName = "suderman@fastmail.com";
            passwordCommand = ["bash" "${pass}" "fastmail"];
            url = "https://caldav.fastmail.com/";
            type = "caldav";
          };
          local = {
            fileExt = ".ics";
            type = "filesystem";
          };
          vdirsyncer = {
            enable = true;
            collections = [
              # Config, Remote, Local
              ["Personal" "80287d4d-d09b-4865-b3e0-80e315491c6f" "Personal"] # Jon@Fastmail
              ["Wife" "5d5661e7-8492-4982-b587-52c7cc67a951" "Wife"] # Janessa@iCloud
              ["Family" "d421551e-94f8-4969-9ca2-f78781706030" "Family"] # Family@iCloud
              ["Work" "ed95445c-6ec6-4de0-9615-df506ef0af37" "Work"] # nonfiction@Gmail
            ];
            conflictResolution = "remote wins";
            metadata = ["color" "displayname" "description" "order"];
          };
          khal = {
            enable = true;
            type = "discover"; # calendar, birthdays, discover
            # priority = 1000;
            # color = "#ff0000";
          };
          qcal.enable = true; # trying out
        };
      };

      # Contacts are stored at ~/.local/share/accounts/contacts
      contact = {
        basePath = dataDir;
        accounts."contacts" = {
          remote = {
            userName = "suderman@fastmail.com";
            passwordCommand = ["bash" "${pass}" "fastmail"];
            url = "https://carddav.fastmail.com/";
            type = "carddav";
          };
          local = {
            type = "filesystem";
            fileExt = ".vcf";
          };
          vdirsyncer = {
            enable = true;
            collections = [
              ["Personal" "Default" "Personal"] # default address book
              ["Shared" "masteruser_autoyk908y8@fastmail.com.Shared" "Shared"]
            ];
            conflictResolution = "remote wins";
          };
          khard.enable = true;
        };
      };

      # Email is stored at ~/.local/share/accounts/mail
      email.maildirBasePath = "${dataDir}/mail";

      # Personal email
      email.accounts."suderman" = rec {
        userName = "suderman@fastmail.com";
        passwordCommand = ["bash" "${pass}" "fastmail"];
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
          extraMailboxes = ["Archive" "Drafts" "Sent" "Trash"];
        };
        notmuch.enable = true;
        msmtp.enable = true;
      };

      # Work email
      email.accounts."nonfiction" = rec {
        userName = "jon@nonfiction.ca";
        passwordCommand = ["bash" "${pass}" "gmail"];
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
          extraMailboxes = ["Archive" "Drafts" "Sent" "Trash"];
        };
        notmuch.enable = true;
        msmtp.enable = true;
      };
    };

    # Email reader
    programs.neomutt.enable = true;

    # IMAP sync
    programs.mbsync.enable = true;
    services.mbsync.enable = true;

    # SMTP client
    programs.msmtp.enable = true; # neomutt will send via msmtp by default if enable

    # Email indexer
    programs.notmuch = {
      enable = true;
      # hooks.preNew = "mbsync --all";
    };

    # DAV sync
    programs.vdirsyncer.enable = true;
    services.vdirsyncer.enable = true;

    programs.qcal.enable = true;
    programs.khal = {
      enable = true;
      package = pkgs.khal; # https://github.com/NixOS/nixpkgs/pull/380358
      settings = {
        default = {
          default_calendar = "fastmail";
          # default_event_alarm = "15m";
          default_event_duration = "30m";
          highlight_event_days = true;
          show_all_days = true; # show days without events too
          timedelta = "7d"; # show 1 week into the future
        };
        keybindings = {
          external_edit = "e";
          export = "w";
          save = "meta w,<0>";
          view = "enter, ";
        };
        highlight_days = {
          method = "fg";
          multiple = "#0000FF";
          multiple_on_overflow = true;
        };
        view = {
          dynamic_days = false;
          event_view_always_visible = true;
          frame = "color";
        };
        # palette = {
        #   header = "'white', 'dark green', default, '#DDDDDD', '#2E7D32'";
        #   "line header" = "'white', 'dark green', default, '#DDDDDD', '#2E7D32'";
        #   footer = "'white', 'black', bold, '#DDDDDD', '#43A047'";
        #   edit = "'white', 'black', default, '#DDDDDD', '#333333'";
        #   "edit focus" = "'white', 'light green', 'bold'";
        #   button = "'black', 'red'";
        # };
      };
    };

    # Address book
    programs.khard.enable = true;
    xdg.configFile."khard/khard.conf".text = let
      path = "${config.home.homeDirectory}/${dataDir}/contacts";
    in
      lib.mkForce ''
        [addressbooks]
        [[personal]]
        path = ${path}/Personal/
        [[shared]]
        path = ${path}/Shared/

        [general]
        default_action=list
        editor=nvim, -i, NONE

        [contact table]
        display=formatted_name
        preferred_email_address_type=pref, work, home
        preferred_phone_number_type=pref, cell, home

        [vcard]
        private_objects=Jabber, Skype, Twitter
      '';
  };
}
