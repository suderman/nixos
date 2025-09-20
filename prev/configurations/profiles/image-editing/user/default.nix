{ config, lib, pkgs, ... }: {

  # cli packages
  home.packages = with pkgs; [ 
    darktable 
    # digikam FIXME: failed to build, retry later
    inkscape 
  ];

  # Custom module
  programs.gimp.enable = true;

}
