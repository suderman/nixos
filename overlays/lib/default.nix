# Personal library of helper functions
{ pkgs, lib, this, ... }: let 

  inherit (builtins) attrNames listToAttrs readDir;
  inherit (pkgs) callPackage stdenv;
  inherit (lib) filterAttrs;

in rec { 

  # Sanity check
  foo = "bar";

  # List of programs/extensions with their application ID and package
  apps = callPackage ./apps.nix {};

  # Force wayland on programs
  enableWayland = callPackage ./wayland.nix {};

  # Home directory for this user
  homeDir = "/${if (stdenv.isLinux) then "home" else "Users"}/${this.user}";

  # List of directory names
  dirNames = path: attrNames (filterAttrs (n: v: v == "directory") (readDir path));

  # # List of directory names containing default.nix
  # moduleDirNames = path: filter(dir: pathExists ("${path}/${dir}/default.nix")) (dirNames path);

}
