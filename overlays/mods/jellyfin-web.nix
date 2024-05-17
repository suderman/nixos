{ final, prev, ... }: 

  # Broken on 23.11
  if prev.this.stable then 

    # https://github.com/NixOS/nixpkgs/issues/312048#issuecomment-2113810483
    prev.jellyfin-web.override {
      buildNpmPackage = final.buildNpmPackage.override {
        nodejs = final.nodejs_20;
      };
    }

  # Works fine on next release (unstable)
  else prev.jellyfin-web
