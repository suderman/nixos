{ self, super, this', ... }: let

  # Extend this with personal library
  this = { lib = callPackage ../lib {}; } // this';

  inherit (self) callPackage;
  inherit (this.lib) enableWayland;

in { 

  # Personal configuration and library
  inherit this;

  # Personal scripts
  nixos-cli = callPackage ./nixos-cli {};
  isy = callPackage ./isy {};
  yo = callPackage ./yo.nix {};
  apps = callPackage ./apps.nix {};

  # Missing packages
  monica = callPackage ./monica {};
  firefox-pwa = callPackage ./firefox-pwa.nix {};
  beeper = callPackage ./beeper.nix {};
  anytype-wayland = callPackage ./anytype.nix {};

  # These packages support Wayland but sometimes need to be persuaded
  dolphin          = enableWayland { type = "qt"; pkg = super.dolphin; bin = "dolphin"; };
  digikam          = enableWayland { type = "qt"; pkg = super.digikam; bin = "digikam"; };
  element-desktop  = enableWayland { type = "electron"; pkg = super.element-desktop; bin = "element-desktop"; };
  owncloud-client  = enableWayland { type = "qt"; pkg = super.owncloud-client; bin = "owncloud"; };
  nextcloud-client = enableWayland { type = "qt"; pkg = super.nextcloud-client; bin = "nextcloud"; };
  plexamp          = enableWayland { type = "electron"; pkg = super.plexamp; bin = "plexamp"; };
  signal-desktop   = enableWayland { type = "electron"; pkg = super.signal-desktop; bin = "signal-desktop"; };
  figma-linux      = enableWayland { type = "electron"; pkg = super.figma-linux; bin = "figma-linux"; };
  # slack           = enableWayland { type = "electron"; pkg = super.slack; bin = "slack"; };
  # _1password-gui  = enableWayland { type = "electron"; pkg = super._1password-gui; bin = "1password"; };

}
