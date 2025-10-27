{lib, ...}: {
  # Default to x86 linux
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Accept agreements for unfree software
  nixpkgs.config = {
    allowUnfree = true;
    nvidia.acceptLicense = true;
  };

  # Temporary workaround
  nixpkgs.config.permittedInsecurePackages = [
    "mbedtls-2.28.10"
    "python3.12-ecdsa-0.19.1"
  ];
}
