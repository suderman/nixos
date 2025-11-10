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

    # IMAP watch
    services.imapnotify.enable = true;

    # SMTP client
    programs.msmtp.enable = true; # neomutt will send via msmtp by default if enabled

    # Email indexer
    programs.notmuch.enable = true;
  };
}
