{ config, lib, pkgs, ... }: let 

  cfg = config.modules.hyprland;
  inherit (builtins) readFile;
  inherit (lib) mkIf;

  systemMonitor = "${pkgs.kitty}/bin/kitty htop";

in {

  config = mkIf cfg.enable {

    programs.waybar = {
      enable = true;
      package = pkgs.waybar; # need >= 0.9.22

      systemd = {
        enable = true;
        target = "hyprland-session";
      };

      settings.bar = {
        layer = "top";
        position = "top";
        height = 35;
        exclusive = true;
        persistent_workspaces = {
          "1" = [ ];
          "2" = [ ];
          "3" = [ ];
          "4" = [ ];
          "5" = [ ];
        };

        # modules layout
        modules-left = [ "custom/launcher" "hyprland/workspaces" ];
        modules-center = [ "clock" "hyprland/window" ];
        modules-right = [ "idle_inhibitor" "network" "temperature" "cpu" "battery" "custom/power" "tray" ];

        # modules config
        "custom/launcher" = {
          on-click = "tofi-drun --drun-launch=true";
          format = " ";
        };
        "hyprland/workspaces" = {
          on-click = "activate";
          all-outputs = true;
          # format = "{icon} {name}";
          format = "{name}";
          disable-scroll = true;
          active-only = false;
          format-icons = {
            default = "󰊠 ";
            persistent = "󰊠 ";
            focused = "󰮯 ";
          };
          show-special = true;
        };
        clock = {
          format = " {:%I:%M %p}";
          # format = "{:%d %A %H:%M}";
          format-alt = " {:%a %b %d, %G}";
          tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
          # tooltip-format = "{:%Y-%m-%d | %H:%M}";
          interval = 60;
          align = 0;
          rotate = 0;
        };
        idle_inhibitor = {
          format = "{icon}";
        };
        network = {
          interval = 1;
          on-click = "eww open --toggle control";
          format-disconnected = "󰤮 ";
          format-wifi = "󰤨 ";
          format-ethernet = " {essid}";
          tooltip = true;
          tooltip-format = ''
            {ifname}
            {ipaddr}/{cidr}
            Up: {bandwidthUpBits}
            Down: {bandwidthDownBits}
          '';
        };
        cpu = {
          # format = " {usage0}%/{usage1}%/{usage2}%/{usage3}%/{usage4}%/{usage5}%/{usage6}%/{usage7}%";
          format = " {load} / {usage}%";
          on-click = systemMonitor;
        };
        temperature = {
          # thermal-zone = 2;
          thermal-zone = 1;
          critical-threshold = 80;
          format-critical = "{temperatureC}°C ";
          format = "{temperatureC}°C ";
        };
        battery = {
          interval = 60;
          format = "{icon}";
          on-click = "eww open --toggle control";
          format-charging = " ";
          format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          format-plugged = "󰚦 ";
          states = { warning = 30; critical = 15; };
          tooltip = true;
        };
        "custom/power" = {
          on-click = "powermenu &";
          format = " ";
        };
        tray = {
          icon-size = 14;
          spacing = 6;
        };
      };

      style = readFile ./waybar.css;

    };

  };

}
