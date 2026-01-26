{pkgs, ...}: {
  # programs.tmux.enable = true;
  programs.tmux = {
    # prefix = "M-/";
    # aggressiveResize = true;
    # baseIndex = 1;
    # customPaneNavigationAndResize = false;
    # keyMode = "vi";
    # newSession = true;
    # # shortcut = "a";
    terminal = "tmux-256color";

    escapeTime = 10;
    # resizeAmount = 10;
    # historyLimit = 10000;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      copycat
      jump
      dracula
      {
        plugin = yank;
        extraConfig =
          # sh
          ''
            # ⌥v (or ⌥y) Copy Mode (similar to Visual Mode in Vim)
            bind-key -n M-v copy-mode
            bind-key -n M-y copy-mode

            # ⌥p Paste buffer
            bind-key -n M-p paste-buffer

            # Use Vim keybindings in Copy Mode
            setw -g mode-keys vi
            unbind-key -T copy-mode-vi Escape
            bind-key -T copy-mode-vi Escape send-keys -X cancel
            bind-key -T copy-mode-vi v send-keys -X begin-selection
            bind-key -T copy-mode-vi M-v send-keys -X rectangle-toggle
          '';
      }
      {
        plugin = extrakto;
        extraConfig =
          # sh
          ''
            set -g set-clipboard on
            set -g @extrakto_clip_tool_run "fg"
            set -g @extrakto_clip_tool "yank"
            set -g @extrakto_popup_size "65%"
            set -g @extrakto_grab_area "window 500"
          '';
      }
    ];
    extraConfig = builtins.readFile ./tmux.conf;
  };

  home.packages = with pkgs; [
    # (writeScriptBin "tmux-popup" (builtins.readFile ./tmux-popup))
    # (writeScriptBin "tmux-cleanup" (builtins.readFile ./tmux-cleanup))
    # (writeScriptBin "yank" (builtins.readFile ./yank))
  ];
}
