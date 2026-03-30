{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.accounts.enable {
    # Email is stored at ~/.local/share/mail
    accounts.email.maildirBasePath = ".local/share/mail";
    persist.storage.directories = [".local/share/mail"];

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
            path = [pkgs.util-linux pkgs.isync pkgs.notmuch];
            text =
              # bash
              ''
                dir=${config.accounts.email.maildirBasePath}/${account}
                mkdir -m700 -p "$dir"

                [[ -e "$dir/.sync-if-1" ]] || echo 0 >"$dir/.sync-if-1"

                if [[ "$(cat "$dir/.sync-if-1")" == "1" ]]; then
                  exec 9>"/run/user/${toString config.home.uid}/${name}.lock"
                  if flock -n 9; then
                    mbsync -V "${account}"
                    notmuch new --verbose
                  fi
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
          Timer.OnCalendar = "*:0/15";
          Timer.Unit = "${name}.service";
          Install.WantedBy = ["timers.target"];
        };
      };

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
      }
      else {};

    # Email indexer
    programs.notmuch = {
      enable = true;

      new = {
        ignore = [
          ".uidvalidity"
          ".mbsyncstate"
          ".sync-if-1"
        ];

        # Do not blindly tag every new message as inbox.
        # post-new will add inbox only for messages in local Inbox.
        tags = ["unread"];
      };
    };

    home.file.".local/share/mail/.notmuch/hooks/post-new" = {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        # Remove inbox everywhere, then re-add it only for actual Inbox mail.
        ${pkgs.notmuch}/bin/notmuch tag -inbox '*'
        ${pkgs.notmuch}/bin/notmuch tag +inbox folder:Inbox

        # Mark local Junk as spam and ensure it is never inbox.
        ${pkgs.notmuch}/bin/notmuch tag +spam -inbox folder:Junk
      '';
    };
  };
}
