{ config, lib, pkgs, ... }: {

  home.packages = with pkgs; [ 
    darktable 
    digikam
    gimp3-with-plugins
    inkscape 
  ];

}
