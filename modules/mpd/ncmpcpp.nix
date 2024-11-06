{ config, osConfig, lib, pkgs, ... }: let

  cfg = osConfig.services.mpd;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enableUser {

    programs.ncmpcpp = {
      enable = true;

      package = pkgs.ncmpcpp.override { 
        visualizerSupport = true; 
        clockSupport = true;
        taglibSupport = true;
      };

      settings = {
        mpd_connection_timeout = 30;
        ignore_leading_the = true;
        # external_editor = "hx";
        message_delay_time = 1;
        playlist_disable_highlight_delay = 2;
        autocenter_mode = "yes";
        centered_cursor = "yes";
        allow_for_physical_item_deletion = "no";
        lines_scrolled = "0";
        follow_now_playing_lyrics = "yes";
        # lyrics_fetchers = "musixmatch";

        # visualizer
        visualizer_data_source = "/tmp/mpd.fifo";
        visualizer_output_name = "mpd_visualizer";
        visualizer_type = "ellipse";
        visualizer_look = "●●";
        visualizer_color = "blue, green";

        # appearance
        playlist_display_mode = "classic";
        user_interface = "classic";
        volume_color = "white";

        # window
        song_window_title_format = "Music";
        statusbar_visibility = "yes";
        header_visibility = "yes";
        titles_visibility = "yes";

        # progress bar
        progressbar_look = "━━━";
        progressbar_color = "black";
        progressbar_elapsed_color = "blue";

        # song list
        song_status_format = "$7%t";
        song_list_format = "$(008)%t$R  $(247)%a$R$5  %l$8";
        song_columns_list_format = "(53)[blue]{tr} (45)[blue]{a}";
        current_item_prefix = "$b$2| ";
        current_item_suffix = "$/b$5";
        now_playing_prefix = "$b$5| ";
        now_playing_suffix = "$/b$5";
        song_library_format = "{{%a - %t} (%b)}|{%f}";

        # colors
        colors_enabled = "yes";
        main_window_color = "blue";
        current_item_inactive_column_prefix = "$b$5";
        current_item_inactive_column_suffix = "$/b$5";
        color1 = "white";
        color2 = "blue";

      };

      bindings = [
        { key = "l"; command = "next_column"; }
        { key = "h"; command = "previous_column"; }
        { key = "k"; command = "scroll_up"; }
        { key = "j"; command = "scroll_down"; }
        { key = "k"; command = "scroll_up"; }
        { key = "J"; command = [ "select_item" "scroll_down" ]; }
        { key = "K"; command = [ "select_item" "scroll_up" ]; }
        { key = "ctrl-k"; command = "move_selected_items_up"; }
        { key = "ctrl-j"; command = "move_selected_items_down"; }
        { key = "ctrl-u"; command = [ "page_up" ]; }
        { key = "ctrl-d"; command = [ "page_down" ]; }
        { key = "g"; command = [ "move_home" ]; }
        { key = "G"; command = [ "move_end" ]; }
        { key = "n"; command = [ "next_found_item" ]; }
        { key = "N"; command = [ "previous_found_item" ]; }
        # { key = "("; command = [ "scroll_up_album" ]; }
        # { key = ")"; command = [ "scroll_down_album" ]; }
        # { key = "{"; command = [ "scroll_up_artist" ]; }
        # { key = "}"; command = [ "scroll_down_artist" ]; }
        { key = "d"; command = [ "delete_playlist_items" ]; }
        { key = "-"; command = [ "volume_down" ]; }
        { key = "="; command = [ "volume_up" ]; }
        { key = "left"; command = [ "master_screen" ]; }
        { key = "right"; command = [ "slave_screen" ]; }
        { key = ";"; command = [ "execute_command" ]; }
        # { key = "["; command = [ "previous_screen" ]; }
        # { key = "]"; command = [ "next_screen" ]; }
        { key = "?"; command = [ "show_help" ]; }
        # { key = "1"; command = [ "show_playlist" ]; }
        # { key = "2"; command = [ "show_browser" ]; }
        # { key = "@"; command = [ "change_browse_mode" ]; }
        # { key = "3"; command = [ "show_search_engine" ]; }
        # { key = "#"; command = [ "reset_search_engine" ]; }
        # { key = "4"; command = [ "show_media_library" "toggle_media_library_columns_mode" ]; }
        # { key = "6"; command = [ "show_playlist_editor" ]; }
        # { key = "7"; command = [ "show_tag_editor" ]; }
        # { key = "8"; command = [ "show_outputs" ]; }
        # { key = "9"; command = [ "show_visualizer" ]; }
        { key = "_"; command = [ "show_server_info" ]; }
        { key = "+"; command = [ "show_clock" ]; }
        { key = "s"; command = [ "stop" ]; }
        { key = "p"; command = [ "pause" ]; }
        { key = "space"; command = [ "pause" ]; }
        { key = ">"; command = [ "next" ]; }
        { key = "<"; command = [ "previous" ]; }
        { key = "backspace"; command = [ "jump_to_parent_directory" ]; }
        { key = "f"; command = [ "seek_forward" ]; }
        { key = "F"; command = [ "seek_backward" ]; }
        { key = "L"; command = [ "show_lyrics" ]; }

        # def_key "r" toggle_repeat
        # def_key "z" toggle_random
        # def_key "y" save_tag_changes
        # def_key "y" start_searching
        # def_key "y" toggle_single
        # def_key "R" toggle_consume
        # def_key "Y" toggle_replay_gain_mode
        # def_key "t" toggle_space_mode
        # def_key "T" toggle_add_mode
        # def_key "|" toggle_mouse
        # def_key "#" toggle_bitrate_visibility
        # def_key "Z" shuffle
        # def_key "x" toggle_crossfade
        # def_key "X" set_crossfade
        # def_key "u" update_database
        # def_key "ctrl_v" sort_playlist
        # def_key "ctrl_r" reverse_playlist
        # def_key "ctrl_f" apply_filter
        # def_key "/" find
        # def_key "/" find_item_forward
        # def_key "?" find
        # def_key "?" find_item_backward
        # def_key "." next_found_item
        # def_key "," previous_found_item
        # def_key "w" toggle_find_mode
        # def_key "e" edit_song
        # def_key "e" edit_library_tag
        # def_key "e" edit_library_album
        # def_key "e" edit_directory_name
        # def_key "e" edit_playlist_name
        # def_key "e" edit_lyrics
        # def_key "i" show_song_info
        # def_key "I" show_artist_info
        # def_key "g" jump_to_position_in_song
        # def_key "v" reverse_selection
        # def_key "V" remove_selection
        # def_key "B" select_album
        # def_key "a" add_selected_items
        # def_key "c" clear_playlist
        # def_key "c" clear_main_playlist
        # def_key "C" crop_playlist
        # def_key "C" crop_main_playlist
        # def_key "m" move_sort_order_up
        # def_key "m" move_selected_items_up
        # def_key "m" toggle_media_library_sort_mode
        # def_key "m" set_visualizer_sample_multiplier
        # def_key "n" move_sort_order_down
        # def_key "n" move_selected_items_down
        # def_key "M" move_selected_items_to
        # def_key "A" add
        # def_key "S" save_playlist
        # def_key "o" jump_to_playing_song
        # def_key "G" jump_to_browser
        # def_key "G" jump_to_playlist_editor
        # def_key "~" jump_to_media_library
        # def_key "E" jump_to_tag_editor
        # def_key "U" toggle_playing_song_centering
        # def_key "P" toggle_display_mode
        # def_key "\\" toggle_interface
        # def_key "!" toggle_separators_between_albums
        # def_key "L" toggle_lyrics_fetcher
        # def_key "F" toggle_fetching_lyrics_in_background
        # def_key "ctrl_l" toggle_screen_lock
        # def_key "`" toggle_browser_sort_mode
        # def_key "`" toggle_library_tag_type
        # def_key "`" refetch_lyrics
        # def_key "`" add_random_items
        # def_key "ctrl_p" set_selected_items_priority
        # def_key "q" quit

      ];
    };

  };

}
