# Personal scripts
{ final, prev, ... }: let 

  inherit (prev) callPackage this;

  bin-foo = { lib, writeShellApplication }: (writeShellApplication { 
    name = "bin-foo"; 
    text = '' echo "Example script 1." '';
  });

  bin-bar = { lib, writeShellApplication }: (writeShellApplication { 
    name = "bin-bar"; 
    text = '' echo "Example script 2." '';
  });

in {

  bin-foo = callPackage bin-foo {};
  bin-bar = callPackage bin-bar {};

}
