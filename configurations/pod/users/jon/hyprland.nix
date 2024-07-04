{ config, lib, pkgs, this, ... }: {

  config.wayland.windowManager.hyprland = {
    enable = true;
    settings = {};
  };

}
