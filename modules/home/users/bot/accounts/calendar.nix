{
  config,
  lib,
  ...
}: let
  account = "calendars";
in {
  config = lib.mkIf config.accounts.enable {
    # bind-mounted from /mnt/main/storage/home/jon/.local/share
    accounts.calendar.basePath = ".local/share";

    accounts.calendar.accounts.${account} = {
      primary = true;
      primaryCollection = "Personal";

      local = {
        type = "filesystem";
        fileExt = ".ics";
      };

      khal = {
        enable = true;
        type = "discover";
      };
    };

    programs.khal = {
      enable = true;
      settings.default.default_calendar = account;
    };
  };
}
