{ flake, perSystem, pkgs, ... }: perSystem.devshell.mkShell {
  devshell.name = "suderman/nixos/iso";
  packages = [
    pkgs.disko
    pkgs.gum
  ];
}
