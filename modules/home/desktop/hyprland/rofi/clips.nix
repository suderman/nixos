# clips
{pkgs, ...}: {
  home.packages = [
    (pkgs.self.mkScript {
      name = "clips";
      text = "rofi-toggle -show clips:rofi-cliphist -show-icons";
    })
  ];

  programs.rofi.extraConfig.modes = ["clips:rofi-cliphist"];

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
