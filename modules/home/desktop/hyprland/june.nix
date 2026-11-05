{
  config,
  lib,
  ...
}: let
  cfg = config.programs.june;
in {
  # June's overlay on Hyprland. June's own module (programs.june.overlay) runs it as a user service with its "June"
  # launcher entry; this adds the daemon's address from daemonHost, a place for the device token that survives the
  # root reset, and the bind. Tapping Alt (keyd's f13, XKB code 191) cycles live June, the strip, and hidden. Rofi
  # takes the same key to switch modes, so the bind lets it through while Rofi is open.
  config = lib.mkIf (cfg.enable && cfg.overlay.enable) {
    programs.june.overlay = {
      url = lib.mkIf (cfg.daemonHost != null) (lib.mkDefault "wss://june.${cfg.daemonHost}/");
      # The token from `june device add` on the daemon's host, copied here once; never in the store.
      tokenFile = lib.mkDefault "${config.home.homeDirectory}/.local/state/june-overlay/token";
    };

    persist.storage.directories = [
      {
        directory = ".local/state/june-overlay";
        mode = "0700";
      }
    ];

    wayland.windowManager.hyprland.lua.features.june =
      # lua
      ''
        hl.bind("code:191", function()
          for _, layer in ipairs(hl.get_layers()) do
            if layer.namespace == "rofi" then
              return
            end
          end
          hl.dispatch(hl.dsp.exec_cmd("june-overlay cycle"))
        end, { description = "June: live June, the strip, hidden", non_consuming = true, ignore_mods = true })
      '';
  };
}
