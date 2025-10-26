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
      format-alt = "{:%A %d %B W%V %Y}";
      on-click-right = "${lib.getExe pkgs.gsimplecal}";
      interval = 60;
      align = 0;
      rotate = 0;
      tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
      calendar = {
        mode = "year";
        mode-mon-col = 3;
        weeks-pos = "right";
        on-scroll = 1;
        on-click-right = "mode";
        format = {
          months = "<span color='#ffead3'><b>{}</b></span>";
          days = "<span color='#ff9aef'><b>{}</b></span>";
          weeks = "<span color='#85dff8'><b>W{}</b></span>";
          weekdays = "<span color='#f2e1d1'><b>{}</b></span>";
          today = "<span color='#ff8994'><b><u>{}</u></b></span>";
        };
      };
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
}
