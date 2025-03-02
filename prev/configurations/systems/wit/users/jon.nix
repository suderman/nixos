{ config, lib, pkgs, profiles, ... }: {

  imports = [
    profiles.desktop # gui apps on all my desktops
    profiles.image-editing # graphics apps 
  ];

}
