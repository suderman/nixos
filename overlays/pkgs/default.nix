{ self, super, ... }: 

let

  # Force package to run in Wayland
  # example:
  # owncloud-client = enableWayland { type = "qt"; pkg = pkgs.owncloud-client; bin = "owncloud"; };
  enableWayland = { type, pkg, bin }: 
    let args = {
      qt = "--set QT_QPA_PLATFORM wayland";
      electron = ''
        --add-flags "--enable-features=UseOzonePlatform" \
        --add-flags "--ozone-platform=wayland" \
        --add-flags "--force-device-scale-factor=2"
      '';
    }; in super.symlinkJoin {
      name = bin;
      paths = [ pkg ];
      buildInputs = [ super.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/${bin} ${args.${type}}\
      '';
    };

in { 

  # Personal scripts
  yo = self.callPackage ./yo.nix { };

  # These packages support Wayland but sometimes need to be persuaded
  _1password-gui  = enableWayland { type = "electron"; pkg = super._1password-gui; bin = "1password"; };
  dolphin         = enableWayland { type = "qt"; pkg = super.dolphin; bin = "dolphin"; };
  element-desktop = enableWayland { type = "electron"; pkg = super.element-desktop; bin = "element-desktop"; };
  owncloud-client = enableWayland { type = "qt"; pkg = super.owncloud-client; bin = "owncloud"; };
  plexamp         = enableWayland { type = "electron"; pkg = super.plexamp; bin = "plexamp"; };
  signal-desktop  = enableWayland { type = "electron"; pkg = super.signal-desktop; bin = "signal-desktop"; };
  # slack           = enableWayland { type = "electron"; pkg = super.slack; bin = "slack"; };

  # Override existing packages
  # chromium = super.chromium.override {
  #   commandLineArgs = "--proxy-server='https=127.0.0.1:3128;http=127.0.0.1:3128'";
  # };

}
