{ self, super, ... }: 

let 

  pkgs = super; 
  lib = super.lib; 
  inherit (builtins) map;
  inherit (pkgs) symlinkJoin makeWrapper;
  inherit (lib) unique;

in { 

  # List of app ids or packages plucked from a list of apps (see overlays/pkgs/app.nix)
  appIds = list: unique (map (app: app.id) (list));
  appPackages = list: unique (map (app: app.package) (list));

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
    }; in symlinkJoin {
      name = bin;
      paths = [ pkg ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/${bin} ${args.${type}}\
      '';
    };

  # Leave my mark
  jonny = "wuz here";

}
