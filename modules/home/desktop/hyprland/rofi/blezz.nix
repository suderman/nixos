# blezz
{
  config,
  pkgs,
  ...
}: let
  cfg = config.programs.rofi;
in {
  home.packages = [
    (pkgs.self.mkScript {
      name = "blezz";
      text = toString [
        "rofi-toggle"
        "-show blezz"
        "-auto-select"
        "-matching normal"
        "-theme-str 'window {width: 30%;}'"
        "${toString cfg.args}"
      ];
    })
  ];

  programs.rofi = {
    plugins = [pkgs.unstable.rofi-blezz];
    mode.slot6 = "blezz";
    args = [
      "-blezz-config ~/.config/rofi/blezz"
      "-blezz-directory Main"
    ];
    rasiConfig = [''blezz { display-name: ""; }''];
  };

  wayland.windowManager.hyprland.lua.features.rofi_blezz =
    # lua
    ''
      util.exec("SUPER + ALT + SPACE", "blezz")
      util.exec("SUPER + SUPER_R", "blezz", { release = true })
    '';

  xdg.configFile."rofi/blezz".text = ''
    Main:
    dir(p, Programs, window-new-symbolic)
    dir(w, Window, window-new-symbolic)
    dir(m, Media, audio-headphones)
    dir(i, Capture, camera)
    dir(t, Toggle, applications-system)
    dir(a, Appearance, preferences-desktop-theme)
    dir(s, Share, folder-publicshare)
    act(h, Shortcuts ⌘F1, desktop-shortcuts, input-keyboard)
    act(r, run, rofi -show run)

    Programs:
    act(k, Kitty ⌘⏎, kitty)
    act(c, Chromium ⌘B, chromium-browser)
    act(f, Firefox ⌘⌥B, firefox)

    Window:
    dir(f, Focus window)
    dir(r, Resize window)
    dir(m, Move window)
    act(q, Close window, hyprctl dispatch 'hl.dsp.window.close()')

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
    act(t, Screen text ⌘Print, bash -c "sleep 0.25 && printscreen text", edit-copy)
    act(q, QR to private clipboard ⌘⇧Print, bash -c "sleep 0.25 && printscreen qr", view-barcode-qr)

    Toggle:
    actReload(t, Title Bars, hypr-toggletitlebars, preferences-desktop)
    actReload(n, Silence/resume notifications ⌘⌥⇧U, notification-mode toggle, notifications-disabled)
    act(p, Presentation help: Waybar cup, notify-send "Presentation mode" "Click the cup in Waybar to inhibit automatic idle actions. Explicit lock and suspend still work.", video-display)

    Appearance:
    act(t, Toggle light/dark ⌘⌥⇧T, desktop-theme toggle, preferences-desktop-theme)
    act(l, Light, desktop-theme light, weather-clear)
    act(d, Dark, desktop-theme dark, weather-clear-night)
    actReload(w, Random wallpaper, wallpaper, preferences-desktop-wallpaper)

    Share:
    act(l, LocalSend, localsend_app, folder-publicshare)
    act(s, Screenshots, thunar "${config.xdg.userDirs.extraConfig.MEDIA or "${config.home.homeDirectory}/media"}/screenshots", camera)
    act(v, Recordings, thunar "${config.xdg.userDirs.extraConfig.MEDIA or "${config.home.homeDirectory}/media"}/screencasts", video)
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
