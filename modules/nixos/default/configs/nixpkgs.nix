{lib, ...}: {
  # Default to x86 linux
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Compatibility layer for programs installed outside of nixpkgs
  programs.nix-ld.enable = true;
}
