# programs.kitty.enable = true;
{ config, lib, pkgs, this, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf mkAfter;

in {

  config = mkIf cfg.enable {

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

    # https://home-manager-options.extranix.com/?query=kitty&release=master
    programs.kitty = {
      enable = true;

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

      # Use additional nerd symbols
      # - see https://github.com/be5invis/Iosevka/issues/248
      # - see https://github.com/ryanoasis/nerd-fonts/wiki/Glyph-Sets-and-Code-Points
      extraConfig = ''

        # Seti-UI + Custom
        symbol_map U+E5FA-U+E6AC Symbols Nerd Font

        # Devicons
        symbol_map U+E700-U+E7C5 Symbols Nerd Font

        # Font Awesome
        symbol_map U+F000-U+F2E0 Symbols Nerd Font

        # Font Awesome Extension
        symbol_map U+E200-U+E2A9 Symbols Nerd Font

        # Material Design Icons
        symbol_map U+F0001-U+F1AF0 Symbols Nerd Font

        # Weather
        symbol_map U+E300-U+E3E3 Symbols Nerd Font

        # Octicons
        symbol_map U+F400-U+F532,U+2665,U+26A1 Symbols Nerd Font

        # Powerline Symbols
        symbol_map U+E0A0-U+E0A2,U+E0B0-U+E0B3 Symbols Nerd Font

        # Powerline Extra Symbols
        symbol_map U+E0A3,U+E0B4-U+E0C8,U+E0CA,U+E0CC-U+E0D4 Symbols Nerd Font

        # IEC Power Symbols
        symbol_map U+23FB-U+23FE,U+2B58 Symbols Nerd Font

        # Font Logos
        symbol_map U+F300-U+F32F Symbols Nerd Font

        # Pomicons
        symbol_map U+E000-U+E00A Symbols Nerd Font

        # Codicons
        symbol_map U+EA60-U+EBEB Symbols Nerd Font

        # Additional sets
        symbol_map U+E276C-U+E2771 Symbols Nerd Font # Heavy Angle Brackets
        symbol_map U+2500-U+259F Symbols Nerd Font # Box Drawing

        # Some symbols not covered by Symbols Nerd Font
        # nonicons contains icons in the range: U+F101-U+F27D
        # U+F167 is HTML logo, but YouTube logo in Symbols Nerd Font
        symbol_map U+F102,U+F116-U+F118,U+F12F,U+F13E,U+F1AF,U+F1BF,U+F1CF,U+F1FF,U+F20F,U+F21F-U+F220,U+F22E-U+F22F,U+F23F,U+F24F,U+F25F nonicons

      '';

    };

  };

}
