{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {

    programs.chromium = {
      enable = true;
    };

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

    # Chromium's PWA/SSB "installed" web apps don't open because the wrong path to chromium is used. 
    # This fixes it to whatever is currently set in the nix profile.
    home.packages = let inherit (config.home) username; in [
      ( pkgs.writeShellScriptBin "fix-chromium-pwa" ''
        for file in /home/${username}/.local/share/applications/chrome-*-Default.desktop; do
          if [ -f "$file" ]; then
            tail -n +2 "$file" > tmpfile && echo '#!/run/current-system/sw/bin/xdg-open' | cat - tmpfile > "$file"; rm -f tmpfile
            sed -i 's|Exec=/nix/store/.*chromium-unwrapped.*libexec/chromium/chromium|Exec=/etc/profiles/per-user/${username}/bin/chromium|g' "$file"
          fi
        done
      '')
    ];

    # keyboard shortcuts
    services.keyd.applications = {
      chromium-browser = {
        "alt.f" = "C-f"; # find in page
        "super.[" = "C-S-tab"; # prev tab
        "super.]" = "macro(C-tab)"; # next tab
        "super.w" = "C-w"; # close tab
        "super.t" = "C-t"; # new tab
      };
    };

    # tag Chromium and Picture-in-Picture windows
    wayland.windowManager.hyprland.settings = {
      windowrulev2 = [
        "tag +web2, class:[Cc]hromium-browser"
        "tag +pip, title:^(Picture in picture)$"
      ];
    };

  };

}
