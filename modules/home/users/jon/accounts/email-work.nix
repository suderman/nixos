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
      passwordCommand = ["cat" config.age.secrets.gmail.path];
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
        mailboxName = " nonfiction";
        extraMailboxes = [
          "Inbox"
          "Archive"
          "Spam"
          "Trash"
          "Drafts"
          "Sent"
        ];
        extraConfig = let
          personal = folder: ''"+/../suderman/${folder}"'';
          work = folder: ''"+/../nonfiction/${folder}"'';
        in ''
          named-mailboxes "󰶈  suderman" ${personal "Archive"}
          named-mailboxes "   Inbox" ${personal "Inbox"}
          named-mailboxes "   Drafts" ${personal "Drafts"}
          named-mailboxes "   Sent" ${personal "Sent"}
          named-mailboxes "   Spam" ${personal "Spam"}
          named-mailboxes "   Trash" ${personal "Trash"}

          named-mailboxes "󰶍  nonfiction" ${work "Archive"}
          named-mailboxes "   Inbox" ${work "Inbox"}
          named-mailboxes "   Drafts" ${work "Drafts"}
          named-mailboxes "   Sent" ${work "Sent"}
          named-mailboxes "   Spam" ${work "Spam"}
          named-mailboxes "   Trash" ${work "Trash"}

          set sort=reverse-last-date-received
          set copy=no
        '';
      };
      mbsync = {
        enable = false; # temporarily disable
        create = "maildir";
        expunge = "both";
        groups.nonfiction.channels = {
          Inbox = {
            farPattern = "INBOX";
            nearPattern = "Inbox";
            extraConfig.Create = "Near";
            extraConfig.Expunge = "Both";
          };
          Archive = {
            farPattern = "Archived Mail"; # must create this label in Gmail
            nearPattern = "Archive";
            extraConfig.Create = "Both";
            extraConfig.Expunge = "Both";
          };
          Junk = {
            farPattern = "[Gmail]/Spam";
            nearPattern = "Spam";
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
        enable = true;
        boxes = ["Inbox"];
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
