# programs.kitty.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.kitty;
  inherit (lib) mkIf mkAfter;

in {

  config = mkIf cfg.enable {

    # https://home-manager-options.extranix.com/?query=kitty&release=master
    programs.kitty = {

      # kitty +kitten themes
      theme = "Catppuccin-Mocha";

      font = {
        name = "JetBrains Mono Regular";
        size = 11.0;
        package = pkgs.jetbrains-mono;
      };

      settings = {

        bold_font = "auto";
        italic_font = "auto";
        bold_italic_font = "auto";
        adjust_line_height = "100%";

        scrollback_lines = 10000;
        enable_audio_bell = false;
        update_check_interval = 0;

        # disable ligatures when cursor is on them
        disable_ligatures = "cursor"; 

        # Window layout
        background_opacity = "0.95";
        hide_window_decorations = "titlebar-only";
        remember_window_size = "no";
        window_padding_width = "0";
        window_logo_alpha = "0";

        # Tab bar
        tab_bar_edge = "top";
        tab_bar_style = "powerline";
        tab_bar_align = "left"; 
        tab_title_template = "{index}: {title}";
        active_tab_font_style = "bold";
        inactive_tab_font_style = "normal";
        tab_activity_symbol = "";

      };

      environment = {
        "LS_COLORS" = "";
      };

      keybindings = {
        "ctrl+insert" = "copy_to_clipboard";
        "shift+insert" = "paste_from_clipboard";
        "ctrl+shift+q" = "close_window";
        "ctrl+shift+n" = "new_os_window_with_cwd";
        "ctrl+shift+t" = "new_tab";
        "ctrl+shift+right" = "next_tab";
        "ctrl+shift+left" = "previous_tab";
        "ctrl+shift+equal" = "change_font_size all +1.0";
        "ctrl+shift+minus" = "change_font_size all -1.0";
        # "super+0" = "change_font_size all 0";
        # "super+r" = "load_config_file";
        # "ctrl+shift+slash" = "launch --type=overlay --stdin-source=@screen_scrollback ${pkgs.fzf}/bin/fzf -m --no-sort --no-mouse --exact -i --tac | ${pkgs.wl-clipboard}/bin/wl-copy";
      };

      shellIntegration.mode = "enabled";
      extraConfig = builtins.readFile ./symbols.conf;

    };

    # keyboard shortcuts
    services.keyd.windows = {
      kitty = {
        "super.t" = "C-S-t"; # new tab
        "super.w" = "C-S-q"; # close tab
        "super.[" = "C-S-left"; # prev tab
        "super.]" = "C-S-right"; # next tab
        "super.n" = "C-S-n"; # new window
        "super.r" = "C-r"; # reload
        "super.c" = "C-insert"; # copy
        "super.p" = "S-insert"; # paste
        "super.equal" = "C-S-equal";
        "super.minus" = "C-S-minus";
        "super.slash" = "macro(C-S-h slash)"; # search scrollback
      };
    };

    home.packages = with pkgs; [ 
      (unstable.nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    ];

    home.shellAliases = {
      icat="kitty +kitten icat";
    };

    programs.zsh = {
      initExtra = mkAfter ''
        # Alias ssh command if using kitty
        [ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
        # Alias diff command if using kitty
        [ "$TERM" = "xterm-kitty" ] && alias diff="kitty +kitten diff"
      '';
    };

  };

}
