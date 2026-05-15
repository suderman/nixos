{
  config,
  flake,
  ...
}: {
  imports =
    [
      flake.homeModules.default
      flake.homeModules.desktop.hyprland
      flake.homeModules.users.jon
    ]
    ++ flake.lib.ls ./.;

  # Programs
  programs.davinci-resolve.enable = true;
  programs.sparrow.enable = true;
  programs.zwift.enable = true;
  programs.opencode.enable = true;
  programs.mmx-cli.enable = true;

  # Gaming
  programs.steam.enable = true;
  programs.dolphin-emu.enable = true;
  programs.citron.enable = true;
  programs.eden.enable = true;
  programs.ryubing.enable = true;

  # Music
  services.mpd.enable = true; # music daemon
  programs.ncmpcpp.enable = true; # old client
  programs.rmpc.enable = true; # new client
  programs.projectm.enable = true; # visualizer

  # User services
  services.syncthing.enable = true;
  services.withings-sync = {
    enable = false;
    secret = ./withings-sync.age;
  };
  services.garmin = {
    enable = false;
    deviceId = "091e_4cda_0000cb7d522d";
    dataDir = "${config.home.homeDirectory}/fenix";
  };

  # User web server
  services.caddy.enable = true;

  # Email, calendars, contacts
  accounts.enable = true;
}
