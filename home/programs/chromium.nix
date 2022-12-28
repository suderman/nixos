{ ... }: {
  # programs.chromium.enable = true
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
  };
}

