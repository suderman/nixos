{ config, lib, pkgs, ... }: let

  cfg = config.services.mpd;
  inherit (config.home) offset;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # NCurses Music Player Client (Plus Plus) is a lot
    home.shellAliases = {
      pp = "ncmpcpp";
    };

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
        autocenter_mode = "yes";
        follow_now_playing_lyrics = "yes";
        ignore_diacritics = "yes";
        default_place_to_search_in = "database";
        system_encoding = "utf-8";
        regular_expressions = "extended";
        message_delay_time = 1;
        playlist_disable_highlight_delay = 2;
        centered_cursor = "yes";
        allow_for_physical_item_deletion = "no";

        # colors
        colors_enabled = "yes";
        main_window_color = "white";
        header_window_color = "cyan";
        volume_color = "green";
        statusbar_color = "white";

        # progress bar
        progressbar_look = "━━━";
        progressbar_color = "black";
        progressbar_elapsed_color = "blue";
        # progressbar_color = "cyan";
        # progressbar_elapsed_color = "white";
        # progressbar_look =  "=>-";

        # current item
        current_item_prefix = "$(blue)$r";
        current_item_suffix = "$/r$(end)";
        current_item_inactive_column_prefix = "$(cyan)$r";
        selected_item_prefix = "✔ ";
        discard_colors_if_item_is_selected = "yes";

        # interface
        user_interface = "alternative"; # "classic"
        alternative_header_first_line_format = "$0$aqqu$/a {$6%a$9 - }{$3%t$9}|{$3%f$9} $0$atqq$/a$9";
        alternative_header_second_line_format = "{{$4%b$9}{ [$8%y$9]}}|{$4%D$9}";

        # visibility
        header_visibility = "yes";
        statusbar_visibility = "yes";
        titles_visibility = "yes";

        # visualizer
        visualizer_data_source = "/tmp/mpd${toString offset}.fifo";
        visualizer_output_name = "mpd_visualizer";
        visualizer_fps = 60;
        visualizer_in_stereo = "yes";
        visualizer_type = "spectrum"; # off wave ellipse spectrum
        visualizer_look = "◆▋"; # ●▮
        visualizer_spectrum_smooth_look = "yes";

        # display modes
        playlist_display_mode = "columns";
        playlist_editor_display_mode = "columns";
        search_engine_display_mode = "columns";
        browser_display_mode = "columns";

        # nav        
        cyclic_scrolling = "yes";
        header_text_scrolling = "yes";
        lines_scrolled = "2";

        # seeking
        incremental_seeking = "yes";
        seek_time = "1";

        # song list
        song_status_format = " $6%a $7⟫⟫ $3%t $7⟫⟫ $4%b ";
        song_list_format = "{$7%a - $9}{$5%t$9}|{$5%f$9}$R{$6%b $9}{$3%l$9}";
        song_columns_list_format = "(10)[blue]{l} (30)[green]{t} (30)[magenta]{a} (30)[yellow]{b}";
        song_library_format = "{{%a - %t} (%b)}|{%f}";
        now_playing_prefix = "$r";
        now_playing_suffix = "🎵$/r";
        jump_to_now_playing_song_at_start = "yes";

        # misc
        display_bitrate = "yes";
        enable_window_title = "yes";
        empty_tag_marker = "";

      };

      bindings = [
        { key = "l"; command = [ "next_column" ]; } # right
        { key = "l"; command = [ "enter_directory" ]; } # right
        { key = "l"; command = [ "run_action" ]; } # right
        { key = "right"; command = [ "next_column" ]; } # right
        { key = "right"; command = [ "enter_directory" ]; } # right
        { key = "right"; command = [ "run_action" ]; } # right
        { key = "h"; command = [ "reset_search_engine" ]; } # left
        { key = "h"; command = [ "previous_column" ]; } # left
        { key = "h"; command = [ "jump_to_parent_directory" ]; } # left
        { key = "left"; command = [ "reset_search_engine" ]; } # left
        { key = "left"; command = [ "previous_column" ]; } # left
        { key = "left"; command = [ "jump_to_parent_directory" ]; } # left
        { key = "j"; command = [ "scroll_down" ]; } # down
        { key = "k"; command = [ "scroll_up" ]; } # up
        { key = "J"; command = [ "select_item" "scroll_down" ]; }
        { key = "K"; command = [ "select_item" "scroll_up" ]; }
        { key = "ctrl-j"; command = [ "move_selected_items_down" ]; }
        { key = "ctrl-k"; command = [ "move_selected_items_up" ]; }
        { key = "ctrl-u"; command = [ "page_up" ]; } # pageup
        { key = "ctrl-d"; command = [ "page_down" ]; } # pagedown
        { key = "g"; command = [ "move_home" ]; } # home
        { key = "G"; command = [ "move_end" ]; } # end 
        { key = "d"; command = [ "delete_playlist_items" ]; } # delete
        { key = "="; command = [ "volume_up" ]; } # +
        { key = ";"; command = [ "execute_command" ]; } # :
        { key = "?"; command = [ "show_help" ]; } # f1
        { key = "f11"; command = [ "show_clock" ]; } # =
        { key = "f12"; command = [ "show_server_info" ]; } # @ 
        { key = "t"; command = [ "show_lyrics" ]; } # l
        { key = "ctrl-t"; command = [ "toggle_lyrics_fetcher" ]; } # l
        { key = "/"; command = [ "find" ]; } # /
        { key = "/"; command = [ "find_item_forward" ]; } # /
        { key = "space"; command = [ "start_searching" ]; } # y
        { key = "space"; command = [ "select_item" ]; } # insert
        { key = "space"; command = [ "toggle_lyrics_update_on_song_change" ]; } 
        { key = "space"; command = [ "toggle_visualization_type" ]; }  
        { key = "a"; command = [ "add_selected_items" ]; } 
        { key = "ctrl-a"; command = [ "add_item_to_playlist" ]; } 
      ];
    };

  };

}
