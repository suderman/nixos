{ config, lib, pkgs, profiles, ... }: {

  imports = with profiles; [
    desktop # gui apps on all my desktops
    video-editing # davinci resolve and others
  ];

  home.packages = with pkgs; [
    loupe
    pkgs.stable.calcure
  ];

}
