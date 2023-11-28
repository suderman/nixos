# Personal scripts
{ self, super, this, ... }: let

  inherit (self) lib callPackage;

in { 

  nixos-cli = callPackage ./nixos-cli {};
  isy = callPackage ./isy {};
  yo = callPackage ./yo {};

}
