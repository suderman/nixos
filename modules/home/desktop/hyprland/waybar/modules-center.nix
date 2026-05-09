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

  wayland.windowManager.hyprland.lua.features.waybar_center = ''
    hl.window_rule({
        name = "gsimplecal-position",
        match = { class = "gsimplecal" },
        move = "((monitor_w*0.458)) (30)",
        opacity = 0.8,
    })
  '';

  # mini-calendar and top center of screen
  wayland.windowManager.hyprland.settings.windowrule = [
    "move ((monitor_w*0.458)) (30), opacity 0.8, match:class gsimplecal"
  ];
}
