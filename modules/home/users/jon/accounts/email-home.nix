{
  config,
  lib,
  pkgs,
  ...
}: let
  account = "suderman";
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
        extraConfig = ''
          ${config.lib.accounts.mailboxes account neomutt.enable}
          set copy=yes
        '';
      };

      mbsync = {
        enable = true;
        groups.${account}.channels = {
          Inbox = {
            farPattern = "INBOX";
            nearPattern = "Inbox";
          };
          Archive = {
            farPattern = "Archive";
            nearPattern = "Archive";
          };
          Junk = {
            farPattern = "Spam";
            nearPattern = "Junk";
          };
          Trash = {
            farPattern = "Trash";
            nearPattern = "Trash";
          };
          Drafts = {
            farPattern = "Drafts";
            nearPattern = "Drafts";
          };
          Sent = {
            farPattern = "Sent";
            nearPattern = "Sent";
          };
        };
      };

      # Trigger mbsync when new email detected in INBOX
      imapnotify = config.lib.accounts.imapnotifyFor account mbsync.enable;

      notmuch = {
        enable = true;
        neomutt.virtualMailboxes = [];
      };

      msmtp.enable = true;
    };
  };
}
