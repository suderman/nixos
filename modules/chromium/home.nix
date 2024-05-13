# programs.chromium.enable = true
{ config, lib, pkgs, ... }:

let 
  cfg = config.programs.chromium;
  user = config.home.username;

in {

  config = lib.mkIf cfg.enable {

    # programs.chromium.commandLineArgs = [ 
    #   "--enable-features=UseOzonePlatform" 
    #   "-ozone-platform=wayland" 
    #   "--gtk-version=4" 
    # ];

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
    home.packages = [
      ( pkgs.writeShellScriptBin "fix-chromium-pwa" ''
        for file in /home/${user}/.local/share/applications/chrome-*-Default.desktop; do
          if [ -f "$file" ]; then
            tail -n +2 "$file" > tmpfile && echo '#!/run/current-system/sw/bin/xdg-open' | cat - tmpfile > "$file"; rm -f tmpfile
            sed -i 's|Exec=/nix/store/.*chromium-unwrapped.*libexec/chromium/chromium|Exec=/etc/profiles/per-user/${user}/bin/chromium|g' "$file"
          fi
        done
      '')
    ];

    # Remap keyboard
    modules.keyd.applications = {
      chromium-browser = {
        "alt.[" = "C-S-tab";
        "alt.]" = "macro(C-tab)";
        "alt.f" = "C-f";
      };
    };

  };

}

