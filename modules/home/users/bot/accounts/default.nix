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
