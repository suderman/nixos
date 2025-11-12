{
  config,
  lib,
  pkgs,
  ...
}: let
  account = "nonfiction";
in {
  # Work email
  config = lib.mkIf config.accounts.enable {
    accounts.email.accounts.${account} = rec {
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
        extraConfig = ''
          ${config.lib.accounts.mailboxes neomutt.enable}
          set copy=no
        '';
      };

      mbsync = {
        enable = false; # enable when ready
        extraConfig.channel.MaxSize = "25m";
        groups.${account}.channels = {
          Inbox = {
            farPattern = "INBOX";
            nearPattern = "Inbox";
          };
          Archive = {
            farPattern = "[Gmail]/All Mail";
            nearPattern = "Archive";
          };
          Junk = {
            farPattern = "[Gmail]/Spam";
            nearPattern = "Junk";
          };
          Trash = {
            farPattern = "[Gmail]/Trash";
            nearPattern = "Trash";
          };
          Drafts = {
            farPattern = "[Gmail]/Drafts";
            nearPattern = "Drafts";
          };
          Sent = {
            farPattern = "[Gmail]/Sent Mail";
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
