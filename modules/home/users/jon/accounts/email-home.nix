{
  config,
  lib,
  pkgs,
  ...
}: {
  # Personal email
  config = lib.mkIf config.accounts.enable {
    accounts.email.accounts."suderman" = rec {
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
        groups.suderman.channels = {
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
        onNotify = "mbsync suderman";
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
