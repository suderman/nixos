{pkgs, ...}: {
  home.packages = with pkgs; [
    audacity
    imagemagick # animate compare composite conjure convert display identify import magick magick-script mogrify montage stream
    inkscape-with-extensions
  ];

  programs.gimp.enable = true;
}
