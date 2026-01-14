{
  lib,
  pkgs,
  ...
}: {
  programs.waybar.settings.bar = {
    modules-center = [
      "clock"
      "custom/screencast"
    ];

    clock = {
      format = "{:%b %e %I:%M %p}";
      # format-alt = "{:%A %d %B W%V %Y}";
      tooltip = false;
      on-click = "${lib.getExe pkgs.gsimplecal}";
      on-click-right = "kitty --class=khal khal interactive";
      interval = 60;
      align = 0;
      rotate = 0;
    };

    "custom/screencast" = {
      on-click = "printscreen video";
      signal = 8;
      return-type = "json";
      exec = pkgs.self.mkScript {
        text =
          # bash
          ''
            if [[ "$(printscreen status)" == "video" ]]; then
              echo '{"text": " 󰻂 ", "tooltip": "Stop recording", "class": "active"}'
            else
              echo '{"text": ""}'
            fi
          '';
      };
    };
  };

  # mini-calendar and top center of screen
  wayland.windowManager.hyprland.settings.windowrule = [
    # "move 45.8% 30,class:gsimplecal"
    # "opacity 0.8,class:gsimplecal"
    "move ((monitor_w*0.45799999999999996)) (30), opacity 0.8, match:class gsimplecal"
  ];
}
