{ self, super, ... }: {

  # obsidian = (prev.me.enableWayland prev.pkgs.obsidian "obsidian");
  aux.enableWayland = drv: bin: drv.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ super.makeWrapper ];
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/${bin} \
      --add-flags "--enable-features=UseOzonePlatform" \
      --add-flags "--ozone-platform=wayland" \
      --add-flags "--force-device-scale-factor=2"
    '';
  });

  aux.userdir = username: "/${if (super.stdenv.isLinux) then "home" else "Users"}/${username}/";

}
