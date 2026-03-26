{
  config,
  lib,
  flake,
  ...
}: {
  imports = flake.lib.ls ./.;
  config = lib.mkIf config.accounts.enable {
    # Passwords for accounts
    age.secrets.fastmail-imap.rekeyFile = ./password-fastmail-imap.age;
    age.secrets.fastmail-dav.rekeyFile = ./password-fastmail-dav.age;
    age.secrets.gmail.rekeyFile = ./password-gmail.age;
  };
}
