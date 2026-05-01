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

    # vdirsyncer needs agenix service to have already run
    systemd.user.services.vdirsyncer.Unit = {
      Requires = ["agenix.service"];
      After = ["agenix.service"];
    };

    # imapnotify needs agenix service to have already run
    systemd.user.services.imapnotify-suderman.Unit = {
      Requires = ["agenix.service"];
      After = ["agenix.service"];
    };
    systemd.user.services.imapnotify-nonfiction.Unit = {
      Requires = ["agenix.service"];
      After = ["agenix.service"];
    };
  };
}
