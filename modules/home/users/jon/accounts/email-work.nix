{
  config,
  lib,
  pkgs,
  ...
}: {
  # Work email
  config = lib.mkIf config.accounts.enable {
    accounts.email.accounts."nonfiction" = rec {
      userName = "jon@nonfiction.ca";
      passwordCommand = toString (pkgs.self.mkScript "cat ${config.age.secrets.gmail.path}");
      flavor = "gmail.com";
      realName = "Jon Suderman";
      address = "jon@nonfiction.ca";
      signature = {
        showSignature = "append";
        text = ''
          ${realName}
          https://www.nonfiction.ca
        '';
      };
      neomutt = {
        enable = true;
        extraConfig = let
          inherit (config.accounts.email) maildirBasePath;
          home = folder: lib.concatStringsSep "/" [maildirBasePath "suderman" folder];
          work = folder: lib.concatStringsSep "/" [maildirBasePath "nonfiction" folder];
        in ''
          named-mailboxes "󰶈  suderman" ${home "Archive"}
          named-mailboxes "   Inbox" ${home "Inbox"}
          named-mailboxes "   Drafts" ${home "Drafts"}
          named-mailboxes "   Sent" ${home "Sent"}
          named-mailboxes "   Junk" ${home "Junk"}
          named-mailboxes "   Trash" ${home "Trash"}

          named-mailboxes "󰶍  nonfiction" ${work "Archive"}
          named-mailboxes "   Inbox" ${work "Inbox"}
          named-mailboxes "   Drafts" ${work "Drafts"}
          named-mailboxes "   Sent" ${work "Sent"}
          named-mailboxes "   Junk" ${work "Junk"}
          named-mailboxes "   Trash" ${work "Trash"}

          set sort=reverse-last-date-received
          set copy=no
        '';
      };
      mbsync = {
        enable = false;
        create = "maildir";
        expunge = "both";
        extraConfig.channel.MaxSize = "25m";
        groups.nonfiction.channels = {
          Inbox = {
            farPattern = "INBOX";
            nearPattern = "Inbox";
            extraConfig.Create = "Near";
            extraConfig.Expunge = "Both";
          };
          Archive = {
            farPattern = "[Gmail]/All Mail";
            nearPattern = "Archive";
            extraConfig.Create = "Near";
            extraConfig.Expunge = "Both";
          };
          Junk = {
            farPattern = "[Gmail]/Spam";
            nearPattern = "Junk";
            extraConfig.Create = "Near";
            extraConfig.Expunge = "Both";
          };
          Trash = {
            farPattern = "[Gmail]/Trash";
            nearPattern = "Trash";
            extraConfig.Create = "Near";
            extraConfig.Expunge = "Both";
          };
          Drafts = {
            farPattern = "[Gmail]/Drafts";
            nearPattern = "Drafts";
            extraConfig.Create = "Near";
            extraConfig.Expunge = "Both";
          };
          Sent = {
            farPattern = "[Gmail]/Sent Mail";
            nearPattern = "Sent";
            extraConfig.Create = "Near";
            extraConfig.Expunge = "Both";
          };
        };
      };
      imapnotify = {
        enable = false;
        boxes = ["INBOX"];
        onNotify = "mbsync nonfiction";
        onNotifyPost = ''
          ${pkgs.libnotify}/bin/notify-send "New mail arrived."
        '';
      };
      notmuch = {
        enable = true;
        neomutt.virtualMailboxes = [];
      };
      msmtp.enable = true;
    };
  };
}
