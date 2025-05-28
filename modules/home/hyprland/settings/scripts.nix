{ config, lib, pkgs, perSystem, ... }: let 

  scripts = with builtins; attrNames( lib.filterAttrs
    ( n: v: v == "regular" && lib.hasSuffix ".sh" n) 
    ( readDir ../scripts )
  );

  path = with pkgs; [ 
    bluez
    config.programs.rofi.finalPackage
    coreutils 
    gawk  
    gettext
    gnugrep
    gnused
    grim 
    hyprland 
    hyprpicker 
    jq 
    keyd
    libnotify 
    procps 
    pulseaudio
    slurp 
    socat
    swappy 
    wl-clipboard 
  ];

in {

  home.packages = map( name: ( 
    perSystem.self.mkScript { 
      inherit path; 
      name = lib.removeSuffix ".sh" name;
      text = ../scripts/${name}; 
    } 
  )) scripts;

}
