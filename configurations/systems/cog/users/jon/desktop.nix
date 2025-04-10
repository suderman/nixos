{ config, lib, pkgs, profiles, ... }: {

  # Hyprland enabled in configuration.nix
  wayland.windowManager.hyprland.settings = {
    monitor = [ # embedded display (laptop)
      "eDP-1, 2256x1504@59.9990001, 500x1440, 1.333333"
    ];
  };

  # Set to false if plugins barf notification errors
  wayland.windowManager.hyprland.enablePlugins = false;

  programs.rofi = {
    extraSinks = [ "bluez_output.AC_3E_B1_9F_43_35.1" ]; # pixel buds pro
    hiddenSinks = [];
  };

  programs.chromium = {
    enable = true;
    unpackedExtensions = {
      alby = "iokeahhehimjnekafflcihljlcjccdbe";
      dark-reader = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
      fake-data = "gchcfdihakkhjgfmokemfeembfokkajj";
      global-speed = "jpbjcnkcffbooppibceonlgknpkniiff";
      i-still-dont-care-about-cookies = "edibdbjcniadpccecjdfdjjppcpchdlm";
      one-password = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
      sponsorblock = "mnjggcdmjocbbbhaepdhchncahnbgone";
      tampermonkey = "dhdgffkkebhmkfjojejmpbldmpobfkfo";
      ublock-origin = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
      ublock-origin-lite = "ddkjiahejlhfcafbddmgiahcphecmpfh";
    };
  };

}
