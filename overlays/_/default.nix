# Personal library of helper functions
{ pkgs, lib, _, ... }: with pkgs; { 

  # Sanity check
  foo = "bar";

  # List of programs/extensions with their application ID and package
  apps = callPackage ./apps.nix {};

  # Force wayland on programs
  enableWayland = callPackage ./wayland.nix {};

}
