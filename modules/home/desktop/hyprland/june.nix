{
  config,
  lib,
  ...
}: let
  cfg = config.programs.june;
in {
  # June's desktop client on Hyprland. June's own module (programs.june.desktop) runs it as a user service with its "June"
  # launcher entry; this adds the daemon's address from daemonHost, a place for the device token that survives the
  # root reset, and the binds. Tapping Alt (keyd's f13, XKB code 191) turns live June, minimised, on and off; Tab in her
  # compose bar opens the full strip, Tab there shrinks it back to her, and Esc puts either away (what `june-desktop
  # cycle` and `mini` do is June's: desktop/shell.qml). While June shows, a long press of Alt (input.repeat_delay)
  # trades the two as Tab does. Rofi takes the same key to switch modes, so the tap is let through while Rofi is open.
  config = lib.mkIf (cfg.enable && cfg.desktop.enable) {
    programs.june.desktop = {
      url = lib.mkIf (cfg.daemonHost != null) (lib.mkDefault "wss://june.${cfg.daemonHost}/");
      # The token from `june device add` on the daemon's host, copied here once; never in the store.
      tokenFile = lib.mkDefault "${config.home.homeDirectory}/.local/state/june-desktop/token";
    };

    persist.storage.directories = [
      {
        directory = ".local/state/june-desktop";
        mode = "0700";
      }
    ];

    wayland.windowManager.hyprland.lua.features.june =
      # lua
      ''
        -- A long press of Alt while June shows trades live June and the full strip (`june-desktop mini`). When Alt is let
        -- go keyd still sends its tap, which would undo the trade, so that one tap is skipped; the next Alt press clears
        -- the skip, so a long press used as a modifier (no tap follows) never leaves it set. Elsewhere Alt is only Alt.
        local june_traded = false
        local function june_showing()
          for _, layer in ipairs(hl.get_layers()) do
            if layer.namespace == "june-desktop" or layer.namespace == "june-live" then
              return true
            end
          end
          return false
        end
        hl.bind("ALT_L", function()
          june_traded = false
        end, { description = "June: a new Alt press", non_consuming = true, ignore_mods = true })
        hl.bind("ALT_L", function()
          if june_showing() then
            june_traded = true
            hl.dispatch(hl.dsp.exec_cmd("june-desktop mini"))
          end
        end, { description = "June: hold Alt to trade live June and the full strip", long_press = true, non_consuming = true, ignore_mods = true })
        hl.bind("code:191", function()
          for _, layer in ipairs(hl.get_layers()) do
            if layer.namespace == "rofi" then
              return
            end
          end
          if june_traded then
            june_traded = false
            return
          end
          hl.dispatch(hl.dsp.exec_cmd("june-desktop cycle"))
        end, { description = "June: live June on and off (Tab or a long press for the full strip)", non_consuming = true, ignore_mods = true })
      '';
  };
}
