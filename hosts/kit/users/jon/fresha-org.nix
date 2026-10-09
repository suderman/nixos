{config, ...}: {
  programs.fresha-org = {
    enable = true;
    orgFile = "${config.home.homeDirectory}/org/calendar/fresha.org";
  };
}
