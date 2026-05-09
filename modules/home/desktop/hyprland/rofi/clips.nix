# clips
{
  config,
  pkgs,
  ...
}: let
  cfg = config.programs.rofi;
in {
  home.packages = [
    (pkgs.self.mkScript {
      name = "clips";
      text = toString [
        "rofi-toggle"
        "-show clips"
        "${toString cfg.args}"
      ];
    })
  ];

  programs.rofi = {
    mode.slot3 = "clips:rofi-cliphist";
    rasiConfig = [''clips { display-name: ""; }''];
  };

  wayland.windowManager.hyprland.lua.features.rofi_clips = ''
    util.exec("SUPER + ALT + V", "clips")
    util.exec("ALT + SHIFT + INSERT", "clips")
  '';

  wayland.windowManager.hyprland.settings.bind = [
    "super+alt, v, exec, clips"
    "alt+shift, insert, exec, clips"
  ];

  services.cliphist = {
    enable = true;
    allowImages = true;
    extraOptions = [
      "-max-dedupe-search"
      "10"
      "-max-items"
      "500"
    ];
  };

  # Persist clipboard history database
  persist.storage.directories = [".cache/cliphist"];
}
