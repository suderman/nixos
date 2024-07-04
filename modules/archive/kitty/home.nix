# modules.kitty.enable = true;
{ config, lib, pkgs, ... }: 

let

  cfg = config.modules.kitty;
  inherit (lib) mkIf mkAfter;
  inherit (config.lib.file) mkOutOfStoreSymlink;

  dir = "/etc/nixos/modules/kitty";

in {

  options.modules.kitty = {
    enable = lib.options.mkEnableOption "kitty"; 
  };

  config = mkIf cfg.enable {

    # fonts
    home.packages = with pkgs; [ 
      jetbrains-mono
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

    programs.kitty = {

      enable = true;

      theme = "GitHub Light";

      settings = {
        scrollback_lines = 10000;
        enable_audio_bell = false;
        update_check_interval = 0;

        # disable ligatures when cursor is on them
        disable_ligatures = "cursor"; 

        # Window layout
        hide_window_decorations = "titlebar-only";
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
        "super+w" = "close_window";
        "super+n" = "new_window";
        "super+t" = "new_tab";
        "super+]" = "next_tab";
        "super+[" = "previous_tab";
        "super+equal" = "change_font_size all +1.0";
        "super+minus" = "change_font_size all -1.0";
        "super+0" = "change_font_size all 0";
        "super+r" = "load_config_file";
      };

      shellIntegration.mode = "enabled";

      extraConfig = ''
        include symbols.conf
        include current-theme.conf
        include local.conf
      '';

    };

    xdg.configFile = {
      "kitty/symbols.conf".source = mkOutOfStoreSymlink "${dir}/symbols.conf";
      "kitty/current-theme.conf".source = mkOutOfStoreSymlink "${dir}/current-theme.conf";
      "kitty/local.conf".source = mkOutOfStoreSymlink "${dir}/local.conf";
    };

  };

}
