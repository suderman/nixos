{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (builtins) attrNames map readDir;
  inherit (lib) filterAttrs hasSuffix mkIf mkShellScript removeSuffix;

  inputs = with pkgs; [ 
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

  scripts = attrNames( filterAttrs
    ( n: v: v == "regular" && hasSuffix ".sh" n) 
    ( readDir ../scripts )
  );

in {

  config = mkIf cfg.enable {

    home.packages = map( name: ( 
      mkShellScript { 
        inherit inputs; 
        name = removeSuffix ".sh" name;
        text = ../scripts/${name}; 
      } 
    )) scripts;

  };

}
