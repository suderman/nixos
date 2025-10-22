# blezz
{pkgs, ...}: {
  home.packages = [
    (pkgs.self.mkScript {
      name = "blezz";
      text = toString [
        "rofi-toggle"
        "-show blezz"
        "-blezz-config ~/.config/rofi/blezz"
        "-blezz-directory Main"
        "-auto-select"
        "-matching normal"
        "-theme-str 'window {width: 30%;}'"
      ];
    })
  ];

  programs.rofi.plugins = [pkgs.unstable.rofi-blezz];

  # Right Super is blezz
  wayland.windowManager.hyprland.settings = {
    bindr = ["super, Super_R, exec, blezz"];
    bind = ["super+alt, space, exec, blezz"];
  };

  xdg.configFile."rofi/blezz".text = ''
    Main:
    dir(p, Programs, window-new-symbolic)
    dir(m, Media, audio-headphones)
    dir(i, Capture, camera)
    dir(t, Toggle, applications-system)
    act(r, run, rofi -show run)

    Programs:
    act(k, Kitty, kitty)
    act(c, Chromium, chromium-browser)
    act(f, Firefox, firefox)

    Media:
    actReload(a, Volume Down, mediactl down, audio-volume-low)
    actReload(s, Volume Up, mediactl up, audio-volume-high)
    actReload(d, Mute, mediactl mute, audio-volume-muted)
    actReload(p, Play/Pause, mediactl play, media-playback-start)
    actReload(f, Forward Play, mediactl forward, media-skip-forward)
    actReload(r, Reverse Play, mediactl reverse, media-skip-backward)
    actReload(z, Brightness Down, mediactl dark, video-display)
    actReload(x, Brightness Up, mediactl light, video-display)
    actReload(c, Sunset toggle, mediactl sunset, weather-clear)
    act(m, Mixer, kitty --class Wiremix wiremix, preferences-desktop-sound)

    Capture:
    act(i, Screenshot, bash -c "sleep 0.25 && printscreen image", camera)
    act(v, Screencast toggle, printscreen video, video)

    Toggle:
    actReload(t, Title Bars, hypr-toggletitlebars, preferences-desktop)
  '';

  # Use a real file for blezz to ease real-time tinkering
  home.localStorePath = [".config/rofi/blezz"];

  # Main = {
  #   r = {
  #     name = "Run";
  #     command = "rofi -show run";
  #   };
  #   m = {
  #     name = "Mute";
  #     icon = "audio-volume-muted";
  #     command = "volumectl mute";
  #     reload = true;
  #   };
  #   a = {
  #     name = "Applications";
  #     icon = "window-new-symbolic";
  #   };
  # };

  # cfg = {
  #   Main = {
  #     r.act = ["Run" "rofi -show run"];
  #     m.actReload = ["Mute" "volumectl mute"];
  #     a.dir = ["Applications" "window-new-symbolic"];
  #   };
  #   Applications = {};
  # };
}
