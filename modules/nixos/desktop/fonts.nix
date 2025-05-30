{ config, pkgs, ... }: {

  fonts.packages = with pkgs; [

    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono 
    nerd-fonts.monofur
    nerd-fonts.symbols-only 

    # serif & sans-serif
    cantarell-fonts
    dejavu_fonts
    eb-garamond
    fira-sans
    liberation_ttf
    merriweather
    montserrat
    noto-fonts
    open-sans
    roboto
    source-sans-pro

    # emoji & symbols
    noto-fonts-emoji
    openmoji-black
    openmoji-color
    symbola
    twemoji-color-font
    twitter-color-emoji
    # joypixels

  ];

}
