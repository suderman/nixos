{lib, ...}: {
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 6000;
      progress-color = lib.mkDefault "over #414559";
      border-radius = 7;
      border-color = lib.mkDefault "#8caaee";
      border-size = 2;
      padding = "15";
      width = 600;
      height = 300;
      text-color = lib.mkDefault "#c6d0f5";
      background-color = lib.mkDefault "#303446";
      font = lib.mkDefault "JetBrainsMono 11";
      anchor = "bottom-left";
      # "[urgency=normal]" = {
      #   border-color = "#ef9f76";
      # };
      # "[urgency=low]" = {
      #   border-color = "#ef9f76";
      # };
      # "[urgency=high]" = {
      #   border-color = "#ef9f76";
      #   default-timeout = "0";
      # };
    };

    # extraConfig = ''
    #   [urgency=normal]
    #   border-color=#ef9f76
    #
    #   [urgency=low]
    #   border-color=#ef9f76
    #
    #   [urgency=high]
    #   border-color=#ef9f76
    #   default-timeout=0
    # '';
    # [mode=do-not-disturb]
    # invisible=1
  };

  wayland.windowManager.hyprland.settings = {
    bindn = [", escape, exec, makoctl dismiss"];
    bind = ["super+alt, u, exec, makoctl restore"];
  };
}
