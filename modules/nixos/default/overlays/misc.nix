{perSystem, ...}: let
  inherit (perSystem.self) enableWayland;
in {
  nixpkgs.overlays = [
    (_final: prev: {
      # These packages support Wayland but sometimes need to be persuaded
      digikam = enableWayland {
        type = "qt";
        package = prev.digikam;
        name = "digikam";
      };
      dolphin = enableWayland {
        type = "qt";
        package = prev.dolphin;
        name = "dolphin";
      };
      element-desktop = enableWayland {
        type = "electron";
        package = prev.element-desktop;
        name = "element-desktop";
      };
      figma-linux = enableWayland {
        type = "electron";
        package = prev.figma-linux;
        name = "figma-linux";
      };
      nextcloud-client = enableWayland {
        type = "qt";
        package = prev.nextcloud-client;
        name = "nextcloud";
      };
      # owncloud-client  = enableWayland { type = "qt"; package = prev.owncloud-client; name = "owncloud"; };
      plexamp = enableWayland {
        type = "electron";
        package = prev.plexamp;
        name = "plexamp";
      };
      signal-desktop = enableWayland {
        type = "electron";
        package = prev.signal-desktop;
        name = "signal-desktop";
      };
      # _1password-gui  = enableWayland { type = "electron"; package = prev._1password-gui; name = "1password"; };
    })
  ];
}
