# config.programs.rofi.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.rofi;
  blezz = toString [
    "rofi-toggle"
    "-show blezz"
    "-blezz-config ~/.config/rofi/blezz"
    "-blezz-directory Main"
    "-auto-select"
    "-matching normal"
    "-theme-str 'window {width: 30%;}'"
  ];
in {
  config = lib.mkIf cfg.enable {
    programs.rofi.plugins = [pkgs.unstable.rofi-blezz];
    wayland.windowManager.hyprland.settings = {
      bindr = [
        "super, Super_R, exec, ${blezz}" # Right Super is blezz
      ];
      bind = [
        "super+alt, space, exec, ${blezz}"
      ];
    };

    xdg.configFile."rofi/blezz".text = ''
      Main:
      act(r, run, rofi -show run)
      dir(a, Audio, audio-headphones)
      dir(p, Programs, window-new-symbolic)

      Audio:
      actReload(a, Volume Down, volumectl -pb down, audio-volume-low)
      actReload(s, Volume Up, volumectl -pbu up, audio-volume-high)
      actReload(d, Mute, volumectl -a toggle-mute, audio-volume-muted)
      actReload(c, Mute Microphone, volumectl -am toggle-mute, audio-input-microphone)
      actReload(p, Play/Pause, playerctl play-pause, media-playback-start)

      Programs:
      act(f, Firefox, firefox)
      act(c, Chromium, chromium-browser)
    '';

    # Use a real file for blezz to ease real-time tinkering
    home.localStorePath = [".config/rofi/blezz"];

    # cfg = {
    #   Main = {
    #     r.act = ["Run" "rofi -show run"];
    #     m.actReload = ["Mute" "volumectl mute"];
    #     a.dir = ["Applications" "window-new-symbolic"];
    #   };
    #   Applications = {};
    # };
  };
}
