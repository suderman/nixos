{
  lib,
  pkgs,
  ...
}: {
  programs.waybar.settings.bar = {
    modules-right = [
      "group/tray"
      "pulseaudio"
      "group/hardware"
      "idle_inhibitor"
      "battery"
      "custom/power"
    ];

    pulseaudio = {
      format = "{icon}  {volume}%";
      format-bluetooth = "{icon}  {volume}%";
      format-muted = "";
      format-icons = {
        headphone = "";
        hands-free = "";
        headset = "";
        phone = "";
        phone-muted = "";
        portable = "";
        car = "";
        default = ["" ""];
      };
      scroll-step = 1;
      on-click = "sinks";
      on-click-right = "kitty --class=wiremix wiremix";
      on-click-middle = "pavucontrol";
      ignored-sinks = [];
    };

    idle_inhibitor = {
      format = "{icon}";
      format-icons = {
        activated = "󰅶";
        deactivated = "󰾪";
      };
    };

    "group/hardware" = {
      orientation = "inherit";
      drawer = {
        transition-duration = 600;
        children-class = "not-power";
        transition-left-to-right = false;
        click-to-reveal = true;
      };
      modules = [
        "temperature"
        "cpu"
        "memory"
        "custom/bluetooth"
        "network"
      ];
    };

    cpu = {
      format = " {usage}%";
      on-click = "kitty --class Btop btop";
    };

    memory = {};

    temperature = {
      thermal-zone = 1; # 2
      critical-threshold = 80;
      # format-critical = "{temperatureC}°C ";
      # format = "{temperatureC}°C ";
      format-critical = "{temperatureC}°C";
      format = "{temperatureC}°C";
    };

    "custom/bluetooth" = {
      on-click = "kitty --class Bluetuith bluetuith";
      format = "󰂯";
    };

    network = {
      interval = 1;
      on-click = "${lib.getExe pkgs.networkmanager_dmenu}";
      format-disconnected = "󰤮 ";
      format-wifi = "󰤨 ";
      format-ethernet = "󰈀 {essid}";
      tooltip = true;
      tooltip-format = ''
        {ifname}
        {ipaddr}/{cidr}
        Up: {bandwidthUpBits}
        Down: {bandwidthDownBits}
      '';
    };

    "group/tray" = {
      orientation = "inherit";
      drawer = {
        transition-duration = 600;
        children-class = "tray-group-item";
      };
      modules = ["custom/tray" "tray"];
    };

    "custom/tray" = {
      format = "";
      tooltip = false;
    };

    tray = {
      icon-size = 16;
      spacing = 6;
    };

    battery = {
      format = "{capacity}% {icon}";
      format-discharging = "{icon}";
      format-charging = "{icon}";
      format-plugged = "";
      format-icons = {
        charging = ["󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅"];
        default = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
      };
    };

    "custom/power" = {
      on-click = "powerkey";
      format = " ";
    };
  };
}
