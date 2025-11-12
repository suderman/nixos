{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.accounts.enable {
    # Email addresses I've used
    age.secrets.addresses.rekeyFile = ./email-addresses.age;

    # Email is stored at ~/.local/share/mail
    accounts.email.maildirBasePath = ".local/share/mail";
    persist.storage.directories = [".local/share/mail"];

    # Email reader
    programs.neomutt = {
      enable = true;
      unmailboxes = true; # we'll manually add named-mailboxes for each account
    };

    # Shared mailbox listing (both accounts) visible in sidebar
    lib.accounts.mailboxes = enable:
      if enable
      then let
        inherit (config.accounts.email) maildirBasePath;
        home = folder: lib.concatStringsSep "/" [maildirBasePath "suderman" folder];
        work = folder: lib.concatStringsSep "/" [maildirBasePath "nonfiction" folder];
      in ''
        # Home mailboxes
        named-mailboxes "󰶍  suderman" ${home "Archive"}
        named-mailboxes "   Inbox" ${home "Inbox"}
        named-mailboxes "   Drafts" ${home "Drafts"}
        named-mailboxes "   Sent" ${home "Sent"}
        named-mailboxes "   Junk" ${home "Junk"}
        named-mailboxes "   Trash" ${home "Trash"}

        # Work mailboxes
        named-mailboxes "󰶍  nonfiction" ${work "Archive"}
        named-mailboxes "   Inbox" ${work "Inbox"}
        named-mailboxes "   Drafts" ${work "Drafts"}
        named-mailboxes "   Sent" ${work "Sent"}
        named-mailboxes "   Junk" ${work "Junk"}
        named-mailboxes "   Trash" ${work "Trash"}

        # Sort emails
        set sort=reverse-last-date-received
      ''
      else "";

    # IMAP sync
    programs.mbsync = {
      enable = true;
      extraConfig = ''
        Sync All # default is all, push and pull changes
        Create Near # default is both, only create local dirs
        Expunge Both # default is both, delete both sides
        CopyArrivalDate yes # default is no, yes to avoid duplicates
        SyncState * # store syncstate inside each mailbox
      '';
    };

    # Name of each account's email unit for systemd
    lib.accounts.unit = account: "email-${account}";

    # Custom replacement for per-account services.mbsync
    systemd.user = let
      # Service to sync with IMAP server only if .sync-if-1 = "1" & one instance at a time
      genService = account: rec {
        name = config.lib.accounts.unit account;
        value = {
          Unit.Description = "email synchronization for ${account}";
          Service.Type = "oneshot";
          Service.ExecStart = pkgs.self.mkScript {
            path = [pkgs.util-linux pkgs.isync pkgs.notmuch]; # sync & index mail
            text =
              # bash
              ''
                # Ensure account directory exists
                dir=${config.accounts.email.maildirBasePath}/${account}
                mkdir -m700 -p $dir

                # Ensure .sync-if-1 exists (default to value of 0)
                [[ -e $dir/.sync-if-1 ]] || echo 0 >$dir/.sync-if-1

                # Only proceed to sync if value of .sync-if-1 equals 1
                if [[ "$(cat $dir/.sync-if-1)" == "1" ]]; then

                  # Wrap mbsync command in flock into ensure only one instance runs
                  flock -n /run/user/${toString config.home.uid}/${name}.lock sh -c '
                    mbsync -V ${account} && notmuch new --verbose
                  '
                fi
              '';
          };
        };
      };

      # Timer for service to syncronize every 15 minutes
      genTimer = account: rec {
        name = config.lib.accounts.unit account;
        value = {
          Unit.Description = "email synchronization for ${account}";
          Timer.OnCalendar = "*:0/15"; # every 15 minutes
          Timer.Unit = "${name}.service";
          Install.WantedBy = ["timers.target"];
        };
      };

      # List of account names where account has mbsync enabled
      accounts = builtins.attrNames (
        lib.filterAttrs (_: a: a.mbsync.enable) config.accounts.email.accounts
      );
    in {
      services = lib.listToAttrs (map genService accounts);
      timers = lib.listToAttrs (map genTimer accounts);
    };

    # IMAP watch
    services.imapnotify.enable = true;

    # Per account settings for imapnotify
    lib.accounts.imapnotifyFor = account: enable:
      if enable
      then {
        enable = true;
        boxes = ["INBOX"];
        onNotify = "${pkgs.systemd}/bin/systemctl --user start ${config.lib.accounts.unit account}";
        onNotifyPost = "${pkgs.libnotify}/bin/notify-send '[${account}] New Mail'";
      }
      else {};

    # SMTP client
    programs.msmtp.enable = true; # neomutt will send via msmtp by default if enabled

    # Email indexer
    programs.notmuch.enable = true;
  };
}
