{ config, lib, pkgs, profiles, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    profiles.desktop # gui apps on all my desktops
    profiles.image-editing # graphics apps 
  ];

}
