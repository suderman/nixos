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
    dir(t, Toggle, applications-system)
    act(r, run, rofi -show run)

    Programs:
    act(k, Kitty, kitty)
    act(c, Chromium, chromium-browser)
    act(f, Firefox, firefox)

    Media:
    actReload(a, Volume Down, volumectl -pb down, audio-volume-low)
    actReload(s, Volume Up, volumectl -pbu up, audio-volume-high)
    actReload(d, Mute, volumectl -a toggle-mute, audio-volume-muted)
    actReload(c, Mute Microphone, volumectl -am toggle-mute, audio-input-microphone)
    actReload(p, Play/Pause, playerctl play-pause, media-playback-start)
    actReload(f, Forward Play, playerctl next, media-skip-forward)
    actReload(r, Reverse Play, playerctl previous, media-skip-backward)
    actReload(z, Brightness Down, lightctl down, video-display)
    actReload(x, Brightness Up, lightctl up, video-display)
    act(m, Mixer, kitty ncpamixer, preferences-desktop-sound)

    Toggle:
    actReload(t, Title Bars, hypr-toggletitlebars, preferences-desktop)
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
}
