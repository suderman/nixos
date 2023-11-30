{ self, super, this', ... }: let

  # Extend this with personal library
  this = super.lib.recursiveUpdate { lib = super.callPackage ../lib {}; } this';

  inherit (this.lib) enableWayland;

# Personal library found in overlays/lib
in { inherit this; } 

# Personal scripts found in overlays/bin
// ( import ../bin { inherit self super; this = this'; } )

// { nftest = this.lib.ls { path = ../bin; }; }

# Additional packages found in overlays/pkgs
// builtins.listToAttrs( map( dir: { name = "${dir}"; value = super.callPackage ./${dir} {}; } ) (this'.lib.ls { path = ./.; full = false; } ) ) 

# Everything else
// {

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
