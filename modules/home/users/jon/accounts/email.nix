{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.accounts.enable {
    # Email addresses I've used
    age.secrets.addresses.rekeyFile = ./email-addresses.age;

    # Email is stored at ~/.local/share/mail
    accounts.email.maildirBasePath = ".local/share/mail";
    persist.storage.directories = [".local/share/mail"];

    # Email reader
    programs.neomutt.enable = true;

    # IMAP sync
    programs.mbsync.enable = true;
    services.mbsync.enable = true;

    # SMTP client
    programs.msmtp.enable = true; # neomutt will send via msmtp by default if enable

    # Email indexer
    programs.notmuch = {
      enable = true;
      # hooks.preNew = "mbsync --all";
    };

    # Ensure 'createMaildir' runs after 'linkGeneration'
    home.activation.createMaildir = lib.mkForce (lib.hm.dag.entryAfter ["linkGeneration"] ''
      run mkdir -m700 -p $VERBOSE_ARG ${
        lib.concatStringsSep " " (lib.mapAttrsToList (_: v: v.maildir.absPath) config.accounts.email.accounts)
      }
    '');
  };
}
