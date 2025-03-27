{ flake, lib, ... }: {

  # Import all *.nix files in this directory
  imports = flake.lib.ls ./.;

  # Default to x86 linux
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Set your time zone.
  time.timeZone = "America/Edmonton";

  # Precious memories 
  system.stateVersion = "24.11";

}
