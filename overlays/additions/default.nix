{ inputs, pkgs }: {

  # Personal scripts
  yo = pkgs.callPackage ./yo.nix { };

}
