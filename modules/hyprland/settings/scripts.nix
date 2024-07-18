{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (builtins) attrNames map readDir;
  inherit (lib) filterAttrs hasSuffix mkIf mkShellScript removeSuffix;

  inputs = with pkgs; [ 
    config.programs.rofi.finalPackage
    coreutils 
    gawk  
    gettext
    grim 
    hyprland 
    hyprpicker 
    jq 
    keyd
    libnotify 
    procps 
    slurp 
    swappy 
    wl-clipboard 
  ];

  scripts = attrNames( filterAttrs
    ( n: v: v == "regular" && hasSuffix ".sh" n) 
    ( readDir ../bin )
  );

in {

  config = mkIf cfg.enable {

    home.packages = map( name: ( 
      mkShellScript { 
        inherit inputs; 
        name = removeSuffix ".sh" name;
        text = ../bin/${name}; 
      } 
    )) scripts;

  };

}
