# Personal packages
{ final, prev, ... }: let

  inherit (prev) callPackage lib this;
  inherit (this.lib) enableWayland;

in {

  # These packages support Wayland but sometimes need to be persuaded
  dolphin          = enableWayland { type = "qt"; pkg = prev.dolphin; bin = "dolphin"; };
  digikam          = enableWayland { type = "qt"; pkg = prev.digikam; bin = "digikam"; };
  element-desktop  = enableWayland { type = "electron"; pkg = prev.element-desktop; bin = "element-desktop"; };
  owncloud-client  = enableWayland { type = "qt"; pkg = prev.owncloud-client; bin = "owncloud"; };
  nextcloud-client = enableWayland { type = "qt"; pkg = prev.nextcloud-client; bin = "nextcloud"; };
  plexamp          = enableWayland { type = "electron"; pkg = prev.plexamp; bin = "plexamp"; };
  signal-desktop   = enableWayland { type = "electron"; pkg = prev.signal-desktop; bin = "signal-desktop"; };
  figma-linux      = enableWayland { type = "electron"; pkg = prev.figma-linux; bin = "figma-linux"; };
  # slack           = enableWayland { type = "electron"; pkg = prev.slack; bin = "slack"; };
  # _1password-gui  = enableWayland { type = "electron"; pkg = prev._1password-gui; bin = "1password"; };

} 
