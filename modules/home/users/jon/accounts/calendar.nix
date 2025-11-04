{
  config,
  lib,
  pkgs,
  ...
}: {
  # I've configured Fastmail to syncronize shared calendars from iCloud & Gmail.
  # This way, I only need to configure the below calendars to talk to Fastmail
  # to sync with my computers.
  config = lib.mkIf config.accounts.enable {
    # Calendars are stored at ~/.local/share/calendars
    persist.storage.directories = [".local/share/calendars"];
    accounts.calendar.basePath = ".local/share";
    accounts.calendar.accounts."calendars" = {
      primary = true;
      primaryCollection = "Personal";
      remote = {
        userName = "suderman@fastmail.com";
        passwordCommand = ["cat" config.age.secrets.fastmail.path];
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
        # priority = 1000;
        # color = "#ff0000";
      };
      qcal.enable = true; # trying out
    };

    # DAV sync
    programs.vdirsyncer.enable = true;
    services.vdirsyncer.enable = true;

    programs.qcal.enable = true;
    programs.khal = {
      enable = true;
      package = pkgs.khal; # https://github.com/NixOS/nixpkgs/pull/380358
      settings = {
        default = {
          default_calendar = "calendars";
          # default_event_alarm = "15m";
          default_event_duration = "30m";
          highlight_event_days = true;
          show_all_days = true; # show days without events too
          timedelta = "7d"; # show 1 week into the future
        };
        keybindings = {
          external_edit = "e";
          export = "w";
          save = "meta w,<0>";
          view = "enter, ";
        };
        highlight_days = {
          method = "fg";
          multiple = "#0000FF";
          multiple_on_overflow = true;
        };
        view = {
          dynamic_days = false;
          event_view_always_visible = true;
          frame = "color";
        };
        # palette = {
        #   header = "'white', 'dark green', default, '#DDDDDD', '#2E7D32'";
        #   "line header" = "'white', 'dark green', default, '#DDDDDD', '#2E7D32'";
        #   footer = "'white', 'black', bold, '#DDDDDD', '#43A047'";
        #   edit = "'white', 'black', default, '#DDDDDD', '#333333'";
        #   "edit focus" = "'white', 'light green', 'bold'";
        #   button = "'black', 'red'";
        # };
      };
    };
  };
}
