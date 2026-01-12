{lib, ...}: {
  # Default to x86 linux
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Accept agreements for unfree software
  nixpkgs.config = {
    allowUnfree = true;
    nvidia.acceptLicense = true;
  };

  # Temporary workarounds
  nixpkgs.config.permittedInsecurePackages = [];
}
