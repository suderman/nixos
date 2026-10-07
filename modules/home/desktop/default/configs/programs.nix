{
  lib,
  pkgs,
  ...
}: {
  # manage ~/.config/mimeapps.list.
  xdg.mimeApps.enable = true;
  xdg.mime.enable = true;

  programs = {
    kitty.enable = true; # terminal
    chromium.enable = true; # browser
    firefox.enable = true; # alt browser

    # Home Automation
    home-assistant = {
      enable = true;
      url = lib.mkDefault "https://hass.hub";
    };
    isy.enable = true;
  };

  # TODO: remove or convert to modules
  services.flatpak.apps = [
    "io.github.dvlv.boxbuddyrs"
    "org.emptyflow.ArdorQuery"
    "com.github.treagod.spectator"
  ];

  home.packages = with pkgs; [
    gnome-disk-utility # format and partition gui
    xeyes # test for x11
    ripdrag # drag + drop files from/to the terminal
  ];

  wayland.windowManager.hyprland.lua.features.ripdrag = ''
    hl.window_rule({
      name = "ripdrag-popup",
      match = { class = "^it[.]catboy[.]ripdrag$" },
      float = true,
      size = { 520, 400 },
    })

    -- Window-open placement can account for panels, unlike rule expressions.
    hl.on("window.open", function(window)
      if window.class ~= "it.catboy.ripdrag" then return end
      local monitor = window.monitor
      local reserved = monitor.reserved
      local cursor = hl.get_cursor_pos()
      local width, height = monitor.width / monitor.scale, monitor.height / monitor.scale
      if monitor.transform % 2 == 1 then width, height = height, width end
      local x = math.max(monitor.x + reserved.left + 8,
        math.min(cursor.x + 16, monitor.x + width - reserved.right - window.size.x - 8))
      local y = math.max(monitor.y + reserved.top + 8,
        math.min(cursor.y + 16, monitor.y + height - reserved.bottom - window.size.y - 8))
      hl.dispatch(hl.dsp.window.move({ window = window, x = x, y = y }))
    end)
  '';
}
