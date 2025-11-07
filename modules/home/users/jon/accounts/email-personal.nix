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
      passwordCommand = ["cat" config.age.secrets.fastmail.path];
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
        mailboxName = " suderman";
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
          named-mailboxes "󰶍  suderman" ${personal "Archive"}
          named-mailboxes "   Inbox" ${personal "Inbox"}
          named-mailboxes "   Drafts" ${personal "Drafts"}
          named-mailboxes "   Sent" ${personal "Sent"}
          named-mailboxes "   Spam" ${personal "Spam"}
          named-mailboxes "   Trash" ${personal "Trash"}

          named-mailboxes "󰶈  nonfiction" ${work "Archive"}
          named-mailboxes "   Inbox" ${work "Inbox"}
          named-mailboxes "   Drafts" ${work "Drafts"}
          named-mailboxes "   Sent" ${work "Sent"}
          named-mailboxes "   Spam" ${work "Spam"}
          named-mailboxes "   Trash" ${work "Trash"}

          set sort=reverse-last-date-received
          set copy=yes
        '';
      };
      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "both";
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
