# programs.tmux.enable = true;
{ config, lib, pkgs, ... }: 

with lib;

let
  cfg = config.programs.tmux;

in {

  config = lib.mkIf cfg.enable {

    # programs.tmux.enable = true;
    programs.tmux = {
      # prefix = "M-z";
      # aggressiveResize = true;
      # baseIndex = 1;
      # customPaneNavigationAndResize = false;
      # keyMode = "vi";
      # newSession = true;
      # # shortcut = "a";
      # terminal = "screen-256color";
      # resizeAmount = 10;
      # historyLimit = 10000;
      plugins = with pkgs.tmuxPlugins; [
        sensible
        copycat
        jump
        dracula
        {
          plugin = yank;
          extraConfig = ''
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
          extraConfig = ''
            set -g set-clipboard on
            set -g @extrakto_clip_tool_run "fg"
            set -g @extrakto_clip_tool "yank"
            set -g @extrakto_popup_size "65%"
            set -g @extrakto_grab_area "window 500"
          '';
        }
        # {
        #   plugin = vim-tmux-navigator;
        #   extraConfig = ''
        #     is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
        #     bind-key -n M-h if-shell "$is_vim" "send-keys M-h"  "select-pane -L"
        #     bind-key -n M-j if-shell "$is_vim" "send-keys M-j"  "select-pane -D"
        #     bind-key -n M-k if-shell "$is_vim" "send-keys M-k"  "select-pane -U"
        #     bind-key -n M-l if-shell "$is_vim" "send-keys M-l"  "select-pane -R"
        #     bind-key -n M-o if-shell "$is_vim" "send-keys M-o"  "select-pane -l"
        #     bind-key -T copy-mode-vi M-h select-pane -L
        #     bind-key -T copy-mode-vi M-j select-pane -D
        #     bind-key -T copy-mode-vi M-k select-pane -U
        #     bind-key -T copy-mode-vi M-l select-pane -R
        #     bind-key -T copy-mode-vi M-o select-pane -l
        #   '';
        # }
      ];
      extraConfig = (builtins.readFile ./tmux.conf);
    };

    home.packages = with pkgs; [
      # (writeScriptBin "tmux-popup" (builtins.readFile ./tmux-popup))
      # (writeScriptBin "tmux-cleanup" (builtins.readFile ./tmux-cleanup))
      # (writeScriptBin "yank" (builtins.readFile ./yank))
    ];

    # Adding helper functions to improve zsh and tmux
    # programs.zsh.initExtraBeforeCompInit = zshrcBeforeCompInit;
    # programs.zsh.initExtra = zshrcExtra;

  };

}
