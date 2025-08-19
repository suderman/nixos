{flake, ...}: {
  # Import all *.nix files in this directory
  imports = flake.lib.ls ./.;
}
