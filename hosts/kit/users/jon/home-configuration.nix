{
  config,
  perSystem,
  flake,
  ...
}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.desktop.hyprland
    flake.homeModules.users.jon
    ./hermes-agent.nix
  ];

  # Hyprland on nvidia desktop
  wayland.windowManager.hyprland = {
    lua = {
      enable = true;
      monitors = [
        {
          output = "DP-1";
          mode = "3840x2160@160.00Hz";
          position = "0x0";
          scale = "1.33";
        }
      ];
      env = {
        LIBVA_DRIVER_NAME = "nvidia";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };
    };
    enablePlugins = false; # dynamic cursors crash on lua path for now
    enableOfficialPlugins = false; # hyprbars/hyprexpo broken on v0.55.0
  };

  # Hide monitor speakers
  sound.hiddenSinks = ["alsa_output.pci-0000_01_00.1.hdmi-stereo"];

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
