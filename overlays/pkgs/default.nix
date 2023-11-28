{ self, super, _, ... }: let

  inherit (self) callPackage;
  _' = _; # rename original _ (underscore)

in rec { 

  # Personal library
  _ = callPackage ../_ {} // _';

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
  dolphin          = _.enableWayland { type = "qt"; pkg = super.dolphin; bin = "dolphin"; };
  digikam          = _.enableWayland { type = "qt"; pkg = super.digikam; bin = "digikam"; };
  element-desktop  = _.enableWayland { type = "electron"; pkg = super.element-desktop; bin = "element-desktop"; };
  owncloud-client  = _.enableWayland { type = "qt"; pkg = super.owncloud-client; bin = "owncloud"; };
  nextcloud-client = _.enableWayland { type = "qt"; pkg = super.nextcloud-client; bin = "nextcloud"; };
  plexamp          = _.enableWayland { type = "electron"; pkg = super.plexamp; bin = "plexamp"; };
  signal-desktop   = _.enableWayland { type = "electron"; pkg = super.signal-desktop; bin = "signal-desktop"; };
  figma-linux      = _.enableWayland { type = "electron"; pkg = super.figma-linux; bin = "figma-linux"; };
  # slack           = _.enableWayland { type = "electron"; pkg = super.slack; bin = "slack"; };
  # _1password-gui  = _.enableWayland { type = "electron"; pkg = super._1password-gui; bin = "1password"; };

}
