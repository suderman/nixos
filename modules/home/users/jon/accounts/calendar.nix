{
  config,
  lib,
  pkgs,
  ...
}: let
  account = "calendars";
in {
  # I've configured Fastmail to syncronize shared calendars from iCloud & Gmail.
  # This way, I only need to configure the below calendars to talk to Fastmail
  # to sync with my computers.
  config = lib.mkIf config.accounts.enable {
    # Calendars are stored at ~/.local/share/calendars
    persist.storage.directories = [".local/share/${account}"];
    accounts.calendar.basePath = ".local/share";
    accounts.calendar.accounts.${account} = {
      primary = true;
      primaryCollection = "Personal";
      remote = {
        userName = "suderman@fastmail.com";
        passwordCommand = ["/run/current-system/sw/bin/cat" config.age.secrets.fastmail.path];
        url = "https://caldav.fastmail.com/";
        type = "caldav";
      };
      local = {
        fileExt = ".ics";
        type = "filesystem";
      };
      vdirsyncer = {
        enable = true;
        collections = [
          # Config, Remote, Local
          ["Personal" "80287d4d-d09b-4865-b3e0-80e315491c6f" "Personal"] # Jon@Fastmail
          ["Wife" "5d5661e7-8492-4982-b587-52c7cc67a951" "Wife"] # Janessa@iCloud
          ["Family" "d421551e-94f8-4969-9ca2-f78781706030" "Family"] # Family@iCloud
          ["Work" "ed95445c-6ec6-4de0-9615-df506ef0af37" "Work"] # nonfiction@Gmail
        ];
        conflictResolution = "remote wins";
        metadata = ["color" "displayname" "description" "order"];
      };
      khal = {
        enable = true;
        type = "discover"; # calendar, birthdays, discover
      };
    };

    # DAV sync
    programs.vdirsyncer.enable = true;
    services.vdirsyncer.enable = true;

    # Put this calendar account on vdirsyncer's radar
    systemd.user.services.vdirsyncer.Service.ExecStart = lib.mkBefore [
      (
        pkgs.self.mkScript {
          path = [config.programs.vdirsyncer.package];
          text = "yes | vdirsyncer discover calendar_${account} || true";
        }
      )
    ];

    programs.khal = {
      enable = true;
      settings.default.default_calendar = account;
    };
  };
}
