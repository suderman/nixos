# programs.rmpc.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.rmpc;
  inherit (lib) mkIf;

  # Python runtime just for yt-dlp extras (mutagen). Keep it OUT of symlinkJoin paths.
  pyYt = pkgs.python3.withPackages (ps: [ps.mutagen]);

  # Wrapped instance of latest rmpc with dependencies for adding youtube urls
  # https://rmpc.mierak.dev/release-0-10-0/guides/youtube
  rmpc-wrapped = pkgs.symlinkJoin {
    name = "rmpc-wrapped";
    paths = [
      pkgs.unstable.rmpc # main program
      pkgs.yt-dlp # rmpc addyt https://www.youtube.com/watch?v=...
      pkgs.ffmpeg # dependencies for yt-dlp
    ];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/rmpc \
        --prefix PATH : ${lib.makeBinPath [pkgs.yt-dlp pkgs.ffmpeg pyYt]}
    '';
  };
in {
  config = mkIf cfg.enable {
    programs.rmpc = {
      package = rmpc-wrapped;
      config = ''
        #![enable(implicit_some)]
        #![enable(unwrap_newtypes)]
        #![enable(unwrap_variant_newtypes)]
        (
          address: "/run/user/${toString config.home.uid}/mpd/socket",
          password: None,
          theme: Some("theme"),
          cache_dir: Some("${config.xdg.dataHome}/rmpc"),
          on_song_change: None,
          volume_step: 5,
          max_fps: 30,
          scrolloff: 0,
          wrap_navigation: false,
          enable_mouse: true,
          enable_config_hot_reload: true,
          status_update_interval_ms: 1000,
          rewind_to_start_sec: None,
          keep_state_on_song_change: true,
          reflect_changes_to_playlist: false,
          select_current_song_on_change: false,
          ignore_leading_the: false,
          browser_song_sort: [Disc, Track, Artist, Title],
          directories_sort: SortFormat(group_by_type: true, reverse: false),
          album_art: (
            method: Auto,
            max_size_px: (width: 1200, height: 1200),
            disabled_protocols: ["http://", "https://"],
            vertical_align: Center,
            horizontal_align: Center,
          ),
          keybinds: (
            global: {
              ":":       CommandMode,
              ",":       VolumeDown,
              "s":       Stop,
              ".":       VolumeUp,
              "<Tab>":   NextTab,
              "<S-Tab>": PreviousTab,
              "1":       SwitchToTab("Queue"),
              "2":       SwitchToTab("Directories"),
              "3":       SwitchToTab("Artists"),
              "4":       SwitchToTab("Album Artists"),
              "5":       SwitchToTab("Albums"),
              "6":       SwitchToTab("Playlists"),
              "7":       SwitchToTab("Search"),
              "q":       Quit,
              ">":       NextTrack,
              "p":       TogglePause,
              "<":       PreviousTrack,
              "f":       SeekForward,
              "z":       ToggleRepeat,
              "x":       ToggleRandom,
              "c":       ToggleConsume,
              "v":       ToggleSingle,
              "b":       SeekBack,
              "?":       ShowHelp,
              "u":       Update,
              "U":       Rescan,
              "I":       ShowCurrentSongInfo,
              "O":       ShowOutputs,
              "P":       ShowDecoders,
              "R":       AddRandom,
            },
            navigation: {
              "k":         Up,
              "j":         Down,
              "h":         Left,
              "l":         Right,
              "<Up>":      Up,
              "<Down>":    Down,
              "<Left>":    Left,
              "<Right>":   Right,
              "<C-k>":     PaneUp,
              "<C-j>":     PaneDown,
              "<C-h>":     PaneLeft,
              "<C-l>":     PaneRight,
              "<C-u>":     UpHalf,
              "N":         PreviousResult,
              "a":         Add,
              "A":         AddAll,
              "r":         Rename,
              "n":         NextResult,
              "g":         Top,
              "<Space>":   Select,
              "<C-Space>": InvertSelection,
              "G":         Bottom,
              "<CR>":      Confirm,
              "i":         FocusInput,
              "J":         MoveDown,
              "<C-d>":     DownHalf,
              "/":         EnterSearch,
              "<C-c>":     Close,
              "<Esc>":     Close,
              "K":         MoveUp,
              "D":         Delete,
              "B":         ShowInfo,
              "<C-z>":     ContextMenu(),
              "<C-s>":     Save(kind: Modal(all: false, duplicates_strategy: Ask)),
            },
            queue: {
              "D":       DeleteAll,
              "<CR>":    Play,
              "a":       AddToPlaylist,
              "d":       Delete,
              "C":       JumpToCurrent,
              "X":       Shuffle,
            },
          ),
          tabs: [
            (
              name: "Queue",
              pane: Split(
                direction: Horizontal,
                panes: [
                  (size: "40%", pane: Pane(AlbumArt)),
                  (size: "60%", pane: Split(
                    direction: Vertical,
                    panes: [
                      (size: "50%", pane: Pane(Queue)),
                      (size: "50%", pane: Pane(Cava)),
                    ],
                  )),
                ],
              ),
            ),
            (
              name: "Directories",
              pane: Pane(Directories),
            ),
            (
              name: "Artists",
              pane: Pane(Artists),
            ),
            (
              name: "Album Artists",
              pane: Pane(AlbumArtists),
            ),
            (
              name: "Albums",
              pane: Pane(Albums),
            ),
            (
              name: "Playlists",
              pane: Pane(Playlists),
            ),
            (
              name: "Search",
              pane: Pane(Search),
            ),
          ],
          search: (
            case_sensitive: false,
            ignore_diacritics: false,
            search_button: false,
            mode: Contains,
            tags: [
              (value: "any",         label: "Any Tag"),
              (value: "artist",      label: "Artist"),
              (value: "album",       label: "Album"),
              (value: "albumartist", label: "Album Artist"),
              (value: "title",       label: "Title"),
              (value: "filename",    label: "Filename"),
              (value: "genre",       label: "Genre"),
            ],
          ),
          artists: (
            album_display_mode: SplitByDate,
            album_sort_by: Date,
            album_date_tags: [Date],
          ),
          cava: (
            framerate: 60, // default 60
            autosens: true, // default true
            sensitivity: 100, // default 100
            lower_cutoff_freq: 50, // not passed to cava if not provided
            higher_cutoff_freq: 10000, // not passed to cava if not provided
            input: (
              method: Fifo,
              source: "/tmp/mpd0.fifo",
              sample_rate: 44100,
              channels: 2,
              sample_bits: 16,
            ),
            smoothing: (
              noise_reduction: 77, // default 77
              monstercat: false, // default false
              waves: false, // default false
            ),
          ),
        )
      '';
      # lyrics_dir: Some("${cfg.musicDirectory}"),
    };

    xdg.configFile."rmpc/theme.ron".text = with config.lib.stylix.colors.withHashtag; ''
      #![enable(implicit_some)]
      #![enable(unwrap_newtypes)]
      #![enable(unwrap_variant_newtypes)]

      (
        default_album_art_path: None,
        show_song_table_header: true,
        draw_borders: false,
        browser_column_widths: [20, 30, 60],
        symbols: (song: " ",dir: " ",marker: " ",ellipsis: "..."),

        tab_bar: (
          enabled: true,
          active_style: (bg: "${base00}", fg: "${base0B}", modifiers: "Bold"),
          inactive_style: (modifiers: ""),
        ),
        highlighted_item_style: (fg: "${base0A}", modifiers: "Bold"),
        current_item_style: (bg: "${base00}", fg: "${base0B}", modifiers: "Underlined | Bold"),
        borders_style: (fg: "${base0A}", modifiers: "Bold"),
        highlight_border_style: (fg: "${base0A}", modifiers: "Bold"),
        progress_bar: (
          symbols: ["", "█", "", "█", ""],
          track_style: (),
          elapsed_style: (fg: "${base05}"),
          thumb_style: (fg: "${base05}"),
        ),
        scrollbar: (
          symbols: ["", "", "", ""],
          track_style: (),
          ends_style: (),
          thumb_style: (),
        ),
        browser_song_format: [
          (
            kind: Group([
              (kind: Property(Track)),
              (kind: Text(" ")),
            ])
          ),
          (
            kind: Group([
              (kind: Property(Title)),
              (kind: Text(" - ")),
              (kind: Property(Artist)),
            ]),
            default: (kind: Property(Filename))
          ),
        ],
        song_table_format: [
          (
            prop: (kind: Property(Artist), style: (),
              default: (kind: Text("Unknown Artist"), style: ())
            ),
            label: " Artist",
            width: "40%",
          ),
          (
            prop: (kind: Property(Title), style: (),
              highlighted_item_style: (modifiers: "Bold"),
              default: (kind: Property(Filename), style: (),)
            ),
            label: "󰦨 Title",
            width: "40%",
          ),
          (
            prop: (kind: Property(Duration), style: ()),
            label: " Time",
            width: "20%",
            alignment: Right,
          ),
        ],
        header: (
          rows: [
            (
              left: [
                (kind: Property(Status(StateV2(playing_label: " [Playing]", paused_label: " [Paused]", stopped_label: " [Stopped]"))), style: (fg: "${base0B}", modifiers: "Bold")),
              ],
              center: [
                (kind: Property(Song(Title)), style: (modifiers: "Bold"),
                  default: (kind: Property(Song(Filename)), style: (modifiers: "Bold"))
                )
              ],
              right: [
                (kind: Text("Volume: "), style: (modifiers: "Bold")),
                (kind: Property(Status(Volume)), style: (modifiers: "Bold")),
                (kind: Text("% "), style: (modifiers: "Bold"))
              ]
            ),
            (
              left: [
                (kind: Property(Status(StateV2(
                  playing_label: " ❚❚ ", paused_label: "  ", stopped_label: "  "))),
                  style: (fg: "${base0B}", modifiers: "Bold"
                )),
                (kind: Property(Status(Elapsed)),style: ()),
                (kind: Text("/"),style: ()),
                (kind: Property(Status(Duration)),style: ()),
              ],
              center: [
                (kind: Property(Song(Artist)), style: (modifiers: "Bold"),
                  default: (kind: Text("No artist found"), style: (modifiers: "Bold"))
                ),
              ],
              right: [
                (kind: Group([
                  (kind: Property(Status(RandomV2(
                    on_label:" ", off_label:" ",
                    on_style: (fg: "${base05}"), off_style: (fg: "${base03}"))
                  ))),
                  (kind: Text(" | "),style: (fg: "${base0A}")),
                  (kind: Property(Status(RepeatV2(
                    on_label:" ", off_label:" ",
                    on_style: (fg: "${base05}"), off_style: (fg: "${base03}"))
                  ))),
                  (kind: Text(" | "),style: (fg: "${base0A}")),
                  (kind: Property(Status(SingleV2(
                    on_label:"󰼏 ", off_label:"󰼏 ", oneshot_label:"󰼏 ",
                    on_style: (fg: "${base05}"), off_style: (fg: "${base03}"), oneshot_style: (fg: "${base0B}"))
                  ))),
                  (kind: Text(" | "),style: (fg: "${base0A}")),
                  (kind: Property(Status(ConsumeV2(
                    on_label:"  ", off_label:"  ", oneshot_label:"  ",
                    on_style: (fg: "${base05}"), off_style: (fg: "${base03}"), oneshot_style: (fg: "${base0B}"))
                  ))),
                ])),
              ]
            ),
          ],
        ),
        layout: Split(
          direction: Vertical,
          panes: [
            (size: "6", pane: Split(
              direction: Horizontal,
              panes: [
                (size: "100%", pane: Split(
                  direction: Vertical,
                  borders: "ALL",
                  panes: [
                    (size: "5", pane: Pane(Header)),
                    (size: "4", pane: Pane(ProgressBar), borders: "TOP"),
                  ],
                )),
              ],
            )),

            (size: "3", pane: Pane(Tabs), borders: "ALL"),
            (size: "100%", pane: Split(
              direction: Horizontal,
              panes: [
                (size: "100%", borders: "ALL", pane: Pane(TabContent)),
              ],
            )),
          ],
        ),
        cava: (
          bar_color: Gradient({
            0: "${base0A}",
            60: "${base05}",
            100: "${base05}",
          }),
        ),
      )
    '';

    # Use a real files to ease real-time tinkering
    home.localStorePath = [
      ".config/rmpc/config.ron"
      ".config/rmpc/theme.ron"
    ];
  };
}
