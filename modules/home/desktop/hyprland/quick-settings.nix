{
  config,
  lib,
  pkgs,
  ...
}: let
  qs = config.wayland.windowManager.hyprland.quickshell;
  actions = [
    {
      id = "light";
      glyph = "󰖨";
      label = "Light";
      command = ["desktop-theme" "light"];
      keepOpen = true;
    }
    {
      id = "dark";
      glyph = "󰖔";
      label = "Dark";
      command = ["desktop-theme" "dark"];
      keepOpen = true;
    }
    {
      id = "notifications";
      glyph = "󰂛";
      label = "Notifications";
      command = ["notification-mode" "toggle"];
      keepOpen = true;
    }
    {
      id = "nightlight";
      glyph = "󰖚";
      label = "Night Light";
      command = ["mediactl" "sunset"];
      keepOpen = true;
    }
    {
      id = "audio";
      glyph = "󰕾";
      label = "Audio Outputs";
      command = ["sinks"];
      keepOpen = false;
    }
    {
      id = "bluetooth";
      glyph = "󰂯";
      label = "Bluetooth";
      command = ["kitty" "--class" "Bluetuith" "bluetuith"];
      keepOpen = false;
    }
    {
      id = "screenshot";
      glyph = "󰹑";
      label = "Screenshot";
      command = ["bash" "-c" "sleep 0.25 && printscreen image"];
      keepOpen = false;
    }
    {
      id = "recording";
      glyph = "󰻃";
      label = "Record Screen";
      command = ["bash" "-c" "sleep 0.25 && printscreen video"];
      keepOpen = false;
    }
    {
      id = "text";
      glyph = "󰊄";
      label = "OCR Text";
      command = ["bash" "-c" "sleep 0.25 && printscreen text"];
      keepOpen = false;
    }
    {
      id = "qr";
      glyph = "󰐳";
      label = "QR Scan";
      command = ["bash" "-c" "sleep 0.25 && printscreen qr"];
      keepOpen = false;
    }
    {
      id = "color";
      glyph = "󰈋";
      label = "Color Picker";
      command = ["bash" "-c" "sleep 0.25 && printscreen color"];
      keepOpen = false;
    }
    {
      id = "localsend";
      glyph = "󰒊";
      label = "LocalSend";
      command = ["localsend_app"];
      keepOpen = false;
    }
  ];
  panel = pkgs.replaceVars ./quickshell/QuickSettings.qml {
    ACTIONS = builtins.toJSON actions;
    FONT = builtins.toJSON config.stylix.fonts.sansSerif.name;
    ICON_FONT = builtins.toJSON config.stylix.fonts.monospace.name;
    FONT_SIZE = toString config.stylix.fonts.sizes.popups;
    WAYBAR_REFRESH = builtins.toJSON ["${pkgs.procps}/bin/pkill" "-RTMIN+11" "-u" config.home.username "-x" "waybar|\\.waybar-wrapped"];
  };
  audio = pkgs.replaceVars ./quickshell/AudioControls.qml {
    FONT = builtins.toJSON config.stylix.fonts.sansSerif.name;
    ICON_FONT = builtins.toJSON config.stylix.fonts.monospace.name;
    FONT_SIZE = toString config.stylix.fonts.sizes.popups;
  };
  brightness = pkgs.replaceVars ./quickshell/BrightnessControls.qml {
    FONT = builtins.toJSON config.stylix.fonts.sansSerif.name;
    ICON_FONT = builtins.toJSON config.stylix.fonts.monospace.name;
    FONT_SIZE = toString config.stylix.fonts.sizes.popups;
  };
  bluetooth = pkgs.replaceVars ./quickshell/BluetoothControls.qml {
    FONT = builtins.toJSON config.stylix.fonts.sansSerif.name;
    ICON_FONT = builtins.toJSON config.stylix.fonts.monospace.name;
    FONT_SIZE = toString config.stylix.fonts.sizes.popups;
  };
  toggle = pkgs.writeShellApplication {
    name = "quick-settings";
    text = ''
      exec ${lib.getExe qs.package} ipc -c ${lib.escapeShellArg qs.configName} call quick-settings toggle
    '';
  };
  status = pkgs.writeShellApplication {
    name = "quick-settings-status";
    text = ''
      if state="$(${lib.getExe qs.package} ipc -c ${lib.escapeShellArg qs.configName} call quick-settings status 2>/dev/null)"; then
        printf '%s\n' "$state"
      else
        printf '%s\n' '{"class":""}'
      fi
    '';
  };
in {
  config = lib.mkIf qs.enable {
    home.packages = [toggle];
    wayland.windowManager.hyprland.quickshell = {
      files."QuickSettings.qml" = panel;
      files."AudioControls.qml" = audio;
      files."BluetoothControls.qml" = bluetooth;
      files."BrightnessControls.qml" = brightness;
      components = ["QuickSettings {}"];
    };
    wayland.windowManager.hyprland.lua.features.quick_settings = ''
      util.exec("SUPER + GRAVE", "quick-settings", { description = "Open quick settings" })
    '';
    programs.waybar.settings.bar = {
      "custom/quick-settings" = {
        format = "󰒓";
        tooltip-format = "Quick settings (Super+`)";
        return-type = "json";
        exec = lib.getExe status;
        interval = "once";
        signal = 11;
        on-click = "quick-settings";
      };
    };
  };
}
