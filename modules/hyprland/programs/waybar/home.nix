{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (builtins) readFile;
  inherit (lib) getExe mkIf mkShellScript mkForce;

  kitty = getExe pkgs.kitty;
  rofi = getExe config.programs.rofi.finalPackage;

  groupies = mkShellScript {
    inputs = with pkgs; [ socat hyprland jq ];
    text = ''
      handle() {
        case $1 in 
          activewindowv2\>\>*)
            hyprctl activewindow -j | jq -r '.grouped | length | if . < 1 then "" else . end' ;;
        esac
      }
      socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
    '';
  };

in {

  config = mkIf cfg.enable {

    systemd.user.services.waybar = {
      Install.WantedBy = mkForce [ cfg.systemd.target ];
      Unit = {
        PartOf = mkForce [ cfg.systemd.target ];
        After = mkForce [ cfg.systemd.target ]; 
      };
    };

    programs.waybar = {
      enable = true;
      package = pkgs.waybar; # need >= 0.9.22

      systemd = {
        enable = true;
        inherit (cfg.systemd) target;
      };

      settings.bar = {
        layer = "top";
        position = "top";
        # position = "bottom";
        height = 39;
        exclusive = true;
        persistent_workspaces = {
          "1" = [ ];
          "2" = [ ];
          "3" = [ ];
          "4" = [ ];
          "5" = [ ];
          "6" = [ ];
          "7" = [ ];
          "8" = [ ];
          "9" = [ ];
          "10" = [ ];
        };

        # modules layout
        modules-left = [ 
          "custom/launcher" 
          # "hyprland/workspaces" 
          "custom/expo" 
          "custom/special" 
          "custom/groupies" 
          # "wlr/taskbar"
        ];
        # modules-center = [ "hyprland/window" ];
        modules-center = [ 
          # "clock" 
          "hyprland/workspaces" 
        ];
        modules-right = [ 
          "idle_inhibitor" 
          "custom/bluetooth" 
          "network" 
          "temperature" 
          "cpu" 
          "tray" 
          "battery" 
          "clock" 
          "custom/power" 
        ];

        # modules config
        "custom/launcher" = {
          on-click = "${rofi} -show combi";
          format = "";
        };

        "custom/expo" = {
          # format = "★";
          # format = "⚃";
          format = "󱗼";
          on-click = "sleep 0.2 && exec hyprctl dispatch hyprexpo:expo toggle";
        };

        #  󰐃
        "custom/special" = {
          format = "󰔷";
          on-click = "exec hyprctl dispatch togglespecialworkspace";
        };

        "custom/groupies" = {
          exec = "${groupies}";
          format = "󰽤 {}";
          on-click = "exec hyprctl dispatch changegroupactive f";
          on-click-right = "exec hyprctl dispatch changegroupactive f";
        };

        "hyprland/workspaces" = {
          on-click = "activate";
          all-outputs = true;
          format = "{name}";
          disable-scroll = true;
          active-only = false;
          show-special = false;
        };

        clock = {
          format = " {:%I:%M %p}";
          format-alt = " {:%a %b %d, %G}";
          tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
          interval = 60;
          align = 0;
          rotate = 0;
        };

        "custom/bluetooth" = {
          on-click = "${kitty} bluetuith";
          format = "󰂯";
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰾪";
          };
        };

        network = {
          interval = 1;
          on-click = "${getExe pkgs.networkmanager_dmenu}";
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

        cpu = {
          format = " {load} / {usage}%";
          on-click = "${kitty} htop";
        };

        temperature = {
          thermal-zone = 1; # 2
          critical-threshold = 80;
          format-critical = "{temperatureC}°C ";
          format = "{temperatureC}°C ";
        };

        "wlr/taskbar" = {
          format = "{icon}";
          icon-size = 14;
          icon-theme = "Numix-Circle";
          tooltip-format = "{title}";
          on-click = "activate";
          on-click-middle = "close";
          ignore-list = [ "kitty" ];
          rewrite = {
            "Firefox Web Browser" = "Firefox";
          };
        };

        tray = {
          icon-size = 14;
          spacing = 6;
        };

        battery = {
          interval = 60;
          format = "{icon}";
          format-charging = " ";
          format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          format-plugged = "󰚦 ";
          states = { warning = 30; critical = 15; };
          tooltip = true;
        };

        "custom/power" = {
          on-click = "powerkey";
          format = " ";
        };

      };

      style = readFile ./style.css;

    };

  };

}
