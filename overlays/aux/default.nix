{ self, super, ... }: {

  aux.enableWayland = { type, pkg, bin }: 
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

  aux.userdir = username: "/${if (super.stdenv.isLinux) then "home" else "Users"}/${username}/";

}
