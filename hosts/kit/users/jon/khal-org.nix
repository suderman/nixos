{config, ...}: let
  calendars = "${config.home.homeDirectory}/.local/share/calendars";
in {
  # Only kit writes the mirrors, so Syncthing sees one writer.
  programs.khal-org = {
    enable = true;
    calendars = {
      family = "${calendars}/Family";
      wife = "${calendars}/Wife";
      work = "${calendars}/Work";
      garbage = "${calendars}/Garbage";
    };
  };
}
