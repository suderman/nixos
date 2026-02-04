{
  config,
  flake,
  ...
}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.desktop.hyprland
    flake.homeModules.users.jon
  ];

  # Hyprland on nvidia desktop
  wayland.windowManager.hyprland = {
    settings = {
      # 4k display
      monitor = ["DP-1, 3840x2160@160.00Hz, 0x0, 1.33"];
      # nvidia fixes
      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      ];
    };
    enablePlugins = true; # set false if plugins barf errors
  };

  # Hide monitor speakers
  sound.hiddenSinks = ["alsa_output.pci-0000_01_00.1.hdmi-stereo"];

  # Programs
  programs.davinci-resolve.enable = true;
  programs.sparrow.enable = true;
  programs.zwift.enable = true;
  programs.opencode.enable = true;
  programs.openclaw.enable = true;

  # Gaming
  programs.steam.enable = true;
  programs.dolphin-emu.enable = true;
  programs.citron.enable = true;

  # Music
  services.mpd.enable = true; # music daemon
  programs.ncmpcpp.enable = true; # old client
  programs.rmpc.enable = true; # new client
  programs.projectm.enable = true; # visualizer

  # User services
  services.syncthing.enable = true;
  services.withings-sync = {
    enable = true;
    secret = ./withings-sync.age;
  };
  services.garmin = {
    enable = false;
    deviceId = "091e_4cda_0000cb7d522d";
    dataDir = "${config.home.homeDirectory}/fenix";
  };

  # Email, calendars, contacts
  accounts.enable = true;

  # Record screen with nvidia's AV1 encoder
  programs.printscreen = {
    codec = "av1_nvenc";
    framerate = 20;
    params = {
      preset = 8;
      cq = 32;
      rc = "vbr";
    };
  };
}
