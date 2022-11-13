{ self, super, ... }: with super.aux; { 

  # Personal scripts
  yo = self.callPackage ./yo.nix { };

  # Override existing packages
  # chromium = super.chromium.override {
  #   commandLineArgs = "--proxy-server='https=127.0.0.1:3128;http=127.0.0.1:3128'";
  # };

  _1password-gui  = enableWayland { type = "electron"; pkg = super._1password-gui; bin = "1password"; };
  dolphin         = enableWayland { type = "qt"; pkg = super.dolphin; bin = "dolphin"; };
  element-desktop = enableWayland { type = "electron"; pkg = super.element-desktop; bin = "element-desktop"; };
  owncloud-client = enableWayland { type = "qt"; pkg = super.owncloud-client; bin = "owncloud"; };
  plexamp         = enableWayland { type = "electron"; pkg = super.plexamp; bin = "plexamp"; };
  signal-desktop  = enableWayland { type = "electron"; pkg = super.signal-desktop; bin = "signal-desktop"; };

}
