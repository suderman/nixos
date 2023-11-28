# Personal scripts
{ self, super, this, ... }: let

  inherit (self) callPackage;

in { 

  nixos-cli = callPackage ./nixos-cli {};
  isy = callPackage ./isy {};
  yo = callPackage ./yo {};

}
