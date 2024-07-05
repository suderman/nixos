{ config, lib, pkgs, this, ... }: {

  config.wayland.windowManager.hyprland.settings = {

    monitor = [ # embedded display (laptop)
      "eDP-1, 2256x1504@59.9990001, 500x1440, 1.333333"
    ];

  };

}
