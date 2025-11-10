{
  config,
  lib,
  pkgs,
  ...
}: let
  account = "suderman";
  unit = "email-${account}";
in {
  # Personal email
  config = lib.mkIf config.accounts.enable {
    accounts.email.accounts.${account} = rec {
      userName = "suderman@fastmail.com";
      passwordCommand = toString (pkgs.self.mkScript "cat ${config.age.secrets.fastmail.path}");
      flavor = "fastmail.com";
      primary = true;
      realName = "Jon Suderman";
      address = "jon@suderman.net";
      signature = {
        showSignature = "append";
        text = ''
          ${realName}
          https://suderman.net
        '';
      };
      neomutt = {
        enable = true;
        extraConfig = let
          inherit (config.accounts.email) maildirBasePath;
          home = folder: lib.concatStringsSep "/" [maildirBasePath "suderman" folder];
          work = folder: lib.concatStringsSep "/" [maildirBasePath "nonfiction" folder];
        in ''
          named-mailboxes "󰶍  suderman" ${home "Archive"}
          named-mailboxes "   Inbox" ${home "Inbox"}
          named-mailboxes "   Drafts" ${home "Drafts"}
          named-mailboxes "   Sent" ${home "Sent"}
          named-mailboxes "   Junk" ${home "Junk"}
          named-mailboxes "   Trash" ${home "Trash"}

          named-mailboxes "󰶈  nonfiction" ${work "Archive"}
          named-mailboxes "   Inbox" ${work "Inbox"}
          named-mailboxes "   Drafts" ${work "Drafts"}
          named-mailboxes "   Sent" ${work "Sent"}
          named-mailboxes "   Junk" ${work "Junk"}
          named-mailboxes "   Trash" ${work "Trash"}

          set sort=reverse-last-date-received
          set copy=yes
        '';
      };
      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "both";
        groups.${account}.channels = {
          Inbox = {
            farPattern = "INBOX";
            nearPattern = "Inbox";
            extraConfig.Create = "Near";
            extraConfig.Expunge = "Both";
          };
          Archive = {
            farPattern = "Archive";
            nearPattern = "Archive";
            extraConfig.Create = "Near";
            extraConfig.Expunge = "Both";
          };
          Junk = {
            farPattern = "Spam";
            nearPattern = "Junk";
            extraConfig.Create = "Near";
            extraConfig.Expunge = "Both";
          };
          Trash = {
            farPattern = "Trash";
            nearPattern = "Trash";
            extraConfig.Create = "Near";
            extraConfig.Expunge = "Both";
          };
          Drafts = {
            farPattern = "Drafts";
            nearPattern = "Drafts";
            extraConfig.Create = "Near";
            extraConfig.Expunge = "Both";
          };
          Sent = {
            farPattern = "Sent";
            nearPattern = "Sent";
            extraConfig.Create = "Near";
            extraConfig.Expunge = "Both";
          };
        };
      };
      imapnotify = {
        enable = true;
        boxes = ["INBOX"];
        onNotify = "${pkgs.systemd}/bin/systemctl --user start ${unit}";
        onNotifyPost = "${pkgs.libnotify}/bin/notify-send '[${account}] New Mail'";
      };
      notmuch = {
        enable = true;
        neomutt.virtualMailboxes = [];
      };
      msmtp.enable = true;
    };

    # Service and timer to syncronize with IMAP server every 15 minutes
    systemd.user = {
      services.${unit} = {
        Unit.Description = "email synchronization for ${account}";
        Service.Type = "oneshot";
        Service.ExecStart = pkgs.self.mkScript {
          path = [pkgs.util-linux pkgs.isync pkgs.notmuch]; # sync & index mail
          text = ''
            mkdir -m700 -p ${config.accounts.email.maildirBasePath}/${account}
            flock -n /run/user/${toString config.home.uid}/${unit}.lock sh -c '
              mbsync -V ${account} && notmuch new --verbose
            '
          '';
        };
      };
      timers.${unit} = {
        Unit.Description = "email synchronization for ${account}";
        Timer.OnCalendar = "*:0/15"; # every 15 minutes
        Timer.Unit = "${unit}.service";
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
