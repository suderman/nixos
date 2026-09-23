{
  pkgs,
  flake,
  ...
}: let
  edger = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "edger";
    version = "unstable";
    src = flake.inputs.edger;
  };
in {
  # programs.tmux.enable = true;
  programs.tmux = {
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
            # Match Herdr's prefix+m copy mode; keep Alt keys for pane apps.
            bind-key m copy-mode
            bind-key v paste-buffer

            setw -g mode-keys vi
            unbind-key -T copy-mode-vi Escape
            bind-key -T copy-mode-vi Escape send-keys -X cancel
            bind-key -T copy-mode-vi m send-keys -X begin-selection
            bind-key -T copy-mode-vi v send-keys -X begin-selection
            # Use tmux-yank's y binding for both keys, including clipboard copy.
            bind-key -T copy-mode-vi c send-keys -K y
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
    extraConfig = ''
      ${builtins.readFile ./tmux.conf}
      run-shell ${edger}/share/tmux-plugins/edger/edger.tmux
    '';
  };

  home.packages = with pkgs; [
    # (writeScriptBin "tmux-popup" (builtins.readFile ./tmux-popup))
    # (writeScriptBin "tmux-cleanup" (builtins.readFile ./tmux-cleanup))
    # (writeScriptBin "yank" (builtins.readFile ./yank))
  ];
}
