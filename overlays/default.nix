{

  # My additions
  additions = final: prev: import ./additions.nix { pkgs = final; };

  # My modifications
  modifications = final: prev: {

    # obsidian = (prev.me.enableWayland prev.pkgs.obsidian "obsidian");
    me.enableWayland = drv: bin: drv.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.pkgs.makeWrapper ];
      postFixup = (old.postFixup or "") + ''
        wrapProgram $out/bin/${bin} \
        --add-flags "--enable-features=UseOzonePlatform" \
        --add-flags "--ozone-platform=wayland"
      '';
    });

  }; 

}
