{ config, lib, pkgs, this, ... }: {

  wayland.windowManager.hyprland.settings = {};

  programs.rofi = {
    extraSinks = [ "bluez_output.AC_3E_B1_9F_43_35.1" ]; # pixel buds pro
    hiddenSinks = [];
  };

}
