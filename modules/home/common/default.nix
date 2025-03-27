{ flake, ... }: {

  # Import all *.nix files in this directory
  imports = flake.lib.ls ./.;

  # Precious memories 
  home.stateVersion = "24.11";

}
