{ self, super, ... }: 

let
  inherit (self.lib) callPackage enableWayland;

in { 

  # Personal scripts
  nixos-cli = self.callPackage ./nixos-cli {};
  isy = self.callPackage ./isy {};
  yo = self.callPackage ./yo.nix {};

  # Missing packages
  monica = self.callPackage ./monica {};

  # These packages support Wayland but sometimes need to be persuaded
  # _1password-gui  = enableWayland { type = "electron"; pkg = super._1password-gui; bin = "1password"; };
  dolphin         = enableWayland { type = "qt"; pkg = super.dolphin; bin = "dolphin"; };
  element-desktop = enableWayland { type = "electron"; pkg = super.element-desktop; bin = "element-desktop"; };
  owncloud-client = enableWayland { type = "qt"; pkg = super.owncloud-client; bin = "owncloud"; };
  plexamp         = enableWayland { type = "electron"; pkg = super.plexamp; bin = "plexamp"; };
  signal-desktop  = enableWayland { type = "electron"; pkg = super.signal-desktop; bin = "signal-desktop"; };
  figma-linux     = enableWayland { type = "electron"; pkg = super.figma-linux; bin = "figma-linux"; };
  # slack           = enableWayland { type = "electron"; pkg = super.slack; bin = "slack"; };

}
