{ pkgs, ... }: {

  home.packages = with pkgs; [ 
    darktable
    fish
    inkscape
    nsxiv
    zsh
  ];

}
