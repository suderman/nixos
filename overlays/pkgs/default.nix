{ self, super, this', ... }: let

  # Extend this with personal library
  this = { lib = super.callPackage ../lib {}; } // this';

  inherit (builtins) attrNames listToAttrs filter map pathExists readDir;
  inherit (super.lib) filterAttrs;
  inherit (this.lib) enableWayland;

  # List of directory names
  dirNames = path: attrNames (filterAttrs (n: v: v == "directory") (readDir path));

  # List of directory names containing default.nix
  moduleDirNames = path: filter(dir: pathExists ("${path}/${dir}/default.nix")) (dirNames path);

# Personal library found in overlays/lib
in { inherit this; } 

# Personal scripts found in overlays/bin
// ( import ../bin { inherit self super this moduleDirNames; } )

# Additional packages found in overlays/pkgs
// listToAttrs( map( dir: { name = "${dir}"; value = super.callPackage ./${dir} {}; } ) (moduleDirNames ./.) ) 

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
