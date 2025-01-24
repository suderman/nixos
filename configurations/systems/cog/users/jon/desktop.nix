{ config, lib, pkgs, profiles, ... }: {

  imports = with profiles; [
    desktop # gui apps on all my desktops
  ];

  home.packages = with pkgs; [
    loupe
    pkgs.stable.calcure
  ];

}
