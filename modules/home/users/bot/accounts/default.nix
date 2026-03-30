{
  config,
  lib,
  flake,
  ...
}: {
  imports = flake.lib.ls ./.;
  config = lib.mkIf config.accounts.enable {
    # Passwords for accounts
    age.secrets.gmail-jon.rekeyFile = ./password-gmail-jon.age;
    age.secrets.fastmail-jon-imap.rekeyFile = ./password-fastmail-jon-imap.age;
    age.secrets.fastmail-jon-dav.rekeyFile = ./password-fastmail-jon-dav.age;
    age.secrets.fastmail.rekeyFile = ./password-fastmail.age;
  };
}
