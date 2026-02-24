{
  config,
  flake,
  ...
}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.desktop.hyprland
    flake.homeModules.users.bot
    ./supervisor.nix
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

  # Enable OpenClaw gateway!
  services.openclaw = {
    enable = true;
    apiKeys = ./openclaw-env.age;
  };

  # Persist login for clawhub
  persist.storage.directories = [
    ".config/clawhub"
  ];

  # User web server
  services.caddy.enable = true;

  # Manage bot's experminetal services
  services.botSupervisor.enable = true;

  # Enable scripting/programming languages
  programs.javascript.enable = true;
  programs.python.enable = true;
  programs.go.enable = true;

  services.syncthing.enable = true;

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
