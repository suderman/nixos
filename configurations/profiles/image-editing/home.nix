{ config, lib, pkgs, ... }: {

  # cli packages
  home.packages = with pkgs; [ 
    darktable 
    digikam
    inkscape 
  ];

  # Custom module
  programs.gimp.enable = true;

}
