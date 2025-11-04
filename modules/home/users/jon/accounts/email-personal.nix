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
        extraConfig = "set sort=reverse-last-date-received";
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
      notmuch.enable = true;
      msmtp.enable = true;
    };
  };
}
