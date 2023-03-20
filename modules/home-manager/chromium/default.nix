# programs.chromium.enable = true
{ config, lib, ... }:

let 
  cfg = config.programs.chromium;

in {

  config = lib.mkIf cfg.enable {

    programs.chromium.commandLineArgs = [ 
      "--enable-features=UseOzonePlatform" 
      "-ozone-platform=wayland" 
      "--gtk-version=4" 
    ];

    xdg.configFile = let flags = ''
      --enable-features=UseOzonePlatform 
      --ozone-platform=wayland
      '';
    in {
      "chromium-flags.conf".text = flags;
      "electron-flags.conf".text = flags;
      "electron-flags16.conf".text = flags;
      "electron-flags17.conf".text = flags;
      "electron-flags18.conf".text = flags;
      "electron-flags19.conf".text = flags;
      "electron-flags20.conf".text = flags;
      "electron-flags21.conf".text = flags;
      "electron-flags22.conf".text = flags;
      "electron-flags23.conf".text = flags;
      "electron-flags24.conf".text = flags;
      "electron-flags25.conf".text = flags;
    };

  };

}

