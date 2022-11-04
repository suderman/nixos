{ config, lib, pkgs, ... }:

with lib;
let
  # cfg = config.hurricane.configs.tmux;
  # zshrcBeforeCompInit = (import ./zshrc-BeforeCompInit.nix pkgs).zshrcBeforeCompInit;
  # zshrcExtra = (import ./zshrc-extra.nix pkgs).zshrcExtra;
  # tmuxConf = (import ./tmux-conf.nix { inherit lib config; }).tmuxConf;
in
{

    home.packages = with pkgs; [
      # (writeScriptBin "tmux-popup" (builtins.readFile ./tmux-popup))
      # (writeScriptBin "tmux-cleanup" (builtins.readFile ./tmux-cleanup))
      # (writeScriptBin "yank" (builtins.readFile ./yank))
    ];

    programs.tmux = {
      enable = true;
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
        {
          plugin = vim-tmux-navigator;
          extraConfig = ''
            is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
            bind-key -n M-h if-shell "$is_vim" "send-keys M-h"  "select-pane -L"
            bind-key -n M-j if-shell "$is_vim" "send-keys M-j"  "select-pane -D"
            bind-key -n M-k if-shell "$is_vim" "send-keys M-k"  "select-pane -U"
            bind-key -n M-l if-shell "$is_vim" "send-keys M-l"  "select-pane -R"
            bind-key -n M-o if-shell "$is_vim" "send-keys M-o"  "select-pane -l"
            bind-key -T copy-mode-vi M-h select-pane -L
            bind-key -T copy-mode-vi M-j select-pane -D
            bind-key -T copy-mode-vi M-k select-pane -U
            bind-key -T copy-mode-vi M-l select-pane -R
            bind-key -T copy-mode-vi M-o select-pane -l
          '';
        }
      ];
      # extraConfig = (builtins.readFile ./tmux.conf);
      extraConfig = ''
        # ⌥z prefix key
        set -g prefix M-z

        # Unbind ^b to free it up
        unbind C-b

        # Set window and pane index to 1 ('0' is at the wrong end of the keyboard)
        set -g base-index 1
        setw -g pane-base-index 1

        # Disallow automatic window naming
        set -g allow-rename off

        # Allow mousing
        set -g mouse on

        # ⌥n New Session
        bind-key -n M-n new
        #
        # ⌥a Switch between Sessions
        bind-key -n M-a choose-session

        # ⌥d Detach self from Session
        bind-key -n M-d detach-client

        # ⌥D Detach others from Session
        bind-key -n M-D detach-client -a

        # ⌥t New Tab 
        bind-key -n M-t new-window -c "#{pane_current_path}"

        # ⌥[ ⌥] Navigate Tabs 
        bind-key -n M-] select-window -t :+
        bind-key -n M-[ select-window -t :-

        # ⌥1 ⌥2 ⌥3 ⌥4 ⌥5 ⌥6 ⌥7 ⌥8 ⌥9 Select Tabs 
        bind-key -n M-1 select-window -t 1
        bind-key -n M-2 select-window -t 2
        bind-key -n M-3 select-window -t 3
        bind-key -n M-4 select-window -t 4
        bind-key -n M-5 select-window -t 5
        bind-key -n M-6 select-window -t 6
        bind-key -n M-7 select-window -t 7
        bind-key -n M-8 select-window -t 8
        bind-key -n M-9 select-window -t 9

        # ^⌥[ ^⌥] Move Tab 
        bind-key -nr C-M-] swap-window -t -1
        bind-key -nr C-M-[ swap-window -t +1

        # ⌥u ⌥i Split Window into Panes (u horizinal, i vertical)
        bind-key -n M-u split-window
        bind-key -n M-i split-window -h

        # ⌥u Rotate Panes
        bind-key -n M-O rotate-window

        # ⌥H ⌥J ⌥K ⌥L Resize Panes
        bind-key -nr M-H resize-pane -L 5
        bind-key -nr M-J resize-pane -D 5
        bind-key -nr M-K resize-pane -U 5
        bind-key -nr M-L resize-pane -R 5

        # ⌥w Close Pane or Window
        bind-key -n M-w kill-pane

        # ⌥; ⌥: Command Mode
        bind-key -n M-\; command-prompt
        bind-key -n M-: command-prompt
      '';
    };

    # Adding helper functions to improve zsh and tmux
    # programs.zsh.initExtraBeforeCompInit = zshrcBeforeCompInit;
    # programs.zsh.initExtra = zshrcExtra;
}
