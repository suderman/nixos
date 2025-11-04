{
  config,
  lib,
  flake,
  ...
}: {
  # yes | vdirsyncer discover
  # vdirsyncer sync
  # vdirsyncer discover calendar_calendars
  # vdirsyncer discover contacts_contacts
  imports = flake.lib.ls ./.;
  config = lib.mkIf config.accounts.enable {
    # Passwords for accounts
    age.secrets.fastmail.rekeyFile = ./password-fastmail.age;
    age.secrets.gmail.rekeyFile = ./password-gmail.age;
    age.secrets.icloud.rekeyFile = ./password-icloud.age;
  };
}
