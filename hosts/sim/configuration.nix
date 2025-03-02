{ flake, inputs, perSystem, pkgs, ... }: {

  imports = [
    # flake.modules.nixos.server
  ];

  environment.systemPackages = [
    # perSystem.nixos-anywhere.default
    pkgs.vim
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "24.11";
}
