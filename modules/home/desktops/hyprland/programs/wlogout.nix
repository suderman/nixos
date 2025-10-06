# powerkey
{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
  swaylock = "${config.programs.swaylock.package}/bin/swaylock";
  systemctl = "${pkgs.systemd}/bin/systemctl";

  # Wrapper script for formatting and prevent multiple instances
  powerkey = perSystem.self.mkScript {
    name = "powerkey";
    path = with pkgs; [procps wlogout];
    text = ''
      if ! $(pidof -q wlogout >/dev/null); then
        wlogout -b 2 -m 300 -L 500 -R 500
      fi
    '';
  };
in {
  # Add wrapper to path
  home.packages = [powerkey];

  # Run wlogout via powerkey button press
  wayland.windowManager.hyprland.settings = {
    bind = [", XF86PowerOff, exec, ${lib.getExe powerkey}"];
  };

  # Configure grid of 4 buttons
  programs.wlogout = {
    enable = true;

    layout = with pkgs; [
      {
        label = "lock";
        # action = "${hyprlock} --immediate";
        action = "${swaylock}";
        text = "lock";
        keybind = "l";
      }
      {
        label = "reboot";
        action = "${systemctl} reboot";
        text = "reboot";
        keybind = "r";
      }
      {
        label = "logout";
        action = "${hyprctl} dispatch exit 0";
        text = "logout";
        keybind = "q";
      }
      {
        label = "shutdown";
        action = "${systemctl} poweroff";
        text = "shutdown";
        keybind = "s";
      }
    ];

    style = ''
      window {
        font-family: JetBrainsMono;
        font-size: 13pt;
        color: #ebdbb2; /* text */
        background-color: rgba(40, 40, 40, 0.76);
      }

      button {
        background-repeat: no-repeat;
        background-position: center;
        background-size: 25%;
        border-style: solid;
        border-radius: 4px;
        border-width: 2px;
        border-color: #ebdbb2;
        background-color: rgba(40, 40, 40, 0.76);
        margin: 10px;
        transition:
          box-shadow 0.3s ease-in-out,
          background-color 0.3s ease-in-out;
      }

      button:hover {
        background-color: rgba(104, 157, 106, 0.92);
        color: #282828;
      }

      button:focus {
        background-color: #ebdbb2;
        color: #282828;
      }

      #lock { background-image: image(url("${../images/lock.png}")); }
      #lock:focus { background-image: image(url("${../images/lock-hover.png}")); }
      #lock:hover { background-image: image(url("${../images/lock-hover.png}")); }

      #logout { background-image: image(url("${../images/logout.png}")); }
      #logout:focus { background-image: image(url("${../images/logout-hover.png}")); }
      #logout:hover { background-image: image(url("${../images/logout-hover.png}")); }

      #shutdown { background-image: image(url("${../images/power.png}")); }
      #shutdown:focus { background-image: image(url("${../images/power-hover.png}")); }
      #shutdown:hover { background-image: image(url("${../images/power-hover.png}")); }

      #reboot { background-image: image(url("${../images/restart.png}")); }
      #reboot:focus { background-image: image(url("${../images/restart-hover.png}")); }
      #reboot:hover { background-image: image(url("${../images/restart-hover.png}")); }

    '';
  };

  # home.localStorePath = [
  #   ".config/wlogout/layout"
  #   ".config/wlogout/style.css"
  # ];
}
