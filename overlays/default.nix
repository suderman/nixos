prev: final: {
  me.enableWayland = drv: bin: drv.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.pkgs.makeWrapper ];
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/${bin} \
      --add-flags "--enable-features=UseOzonePlatform" \
      --add-flags "--ozone-platform=wayland"
    '';
  });
  # me.obsidian = (prev.me.enableWayland prev.pkgs.obsidian "obsidian");
} 
