{ config, hostname, lib, pkgs, ... }: {

  programs.zsh = {
    autocd = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    defaultKeymap = "viins"; # emacs, vicmd, or viins
    history = {
      expireDuplicatesFirst = true;
      extended = true;
      ignoreDups = true;
      ignorePatterns = [ ];
      ignoreSpace = false;
      save = 10000;
      share = true;
      size = 10000;
    };

    initExtra = ''
      # source /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
      # source /home/$USER/.nix-profile/etc/profile.d/hm-session-vars.sh
      # source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
      # source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
    '';

    shellAliases = {
      switch = "echo nixos-rebuild switch --flake /nix/system#$(hostname) && sudo nixos-rebuild switch --flake /nix/system#$(hostname)";
    };

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
    };

    # prezto = {
    #   enable = true;
    #   autosuggestions.color = "fg=magenta"; # Set the query found color. Type: null or string Default: null Example: "fg=blue" Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   caseSensitive =
    #     false; # Set case-sensitivity for completion, history lookup, etc. Type: null or boolean Default: null Example: true Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   color = true; # Color output (auto set to 'no' on dumb terminals) Type: null or boolean Default: true Example: false Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # completions.ignoredHosts = ; # Set the entries to ignore in static */etc/hosts* for host completion. Type: list of string Default: [ ] Example: [ "0.0.0.0" "127.0.0.1" ] Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # editor.dotExpansion = ; # Auto convert .... to ../.. Type: null or boolean Default: null Example: true Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   editor.keymap =
    #     "vi"; # Set the key mapping style to 'emacs' or 'vi'. Type: null or one of "emacs", "vi" Default: "emacs" Example: "vi" Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # editor.promptContext = ; # Allow the zsh prompt context to be shown. Type: null or boolean Default: null Example: true Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # extraConfig = ; # Additional configuration to add to .zpreztorc. Type: strings concatenated with "\n" Default: "" Declared by: <home-manager/modules/programs/zsh/prezto.nix> programs.zsh.prezto.extraFunctions = ; # Set the Zsh functions to load (man zshcontrib). Type: list of string Default: [ ] Example: [ "zargs" "zmv" ] Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # extraModules = ; # Set the Zsh modules to load (man zshmodules). Type: list of string Default: [ ] Example: [ "attr" "stat" ] Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # git.submoduleIgnore = ; # Ignore submodules when they are 'dirty', 'untracked', 'all', or 'none'. Type: null or one of "dirty", "untracked", "all", "none" Default: null Example: "all" Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # gnuUtility.prefix = ; # Set the command prefix on non-GNU systems. Type: null or string Default: null Example: "g" Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # historySubstring.foundColor = ; # Set the query found color. Type: null or string Default: null Example: "fg=blue" Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # historySubstring.globbingFlags = ; # Set the search globbing flags. Type: null or string Default: null Declared by: <home-manager/modules/programs/zsh/prezto.nix> programs.zsh.prezto.historySubstring.notFoundColor = ; # Set the query not found color. Type: null or string Default: null Example: "fg=red" Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # macOS.dashKeyword = ; # Set the keyword used by `mand` to open man pages in Dash.app Type: null or string Default: null Example: "manpages" Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # pmoduleDirs = ; # Add additional directories to load prezto modules from Type: list of path Default: [ ] Example: [ "$HOME/.zprezto-contrib" ] Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   pmodules = [
    #     "environment"
    #     "terminal"
    #     "editor"
    #     "history"
    #     "directory"
    #     "spectrum"
    #     "utility"
    #     "completion"
    #     "prompt"
    #     "autosuggestions"
    #     "ssh"
    #   ];
    #   # prompt.pwdLength = ; # Set the working directory prompt display length. By default, it is set to 'short'. Set it to 'long' (without '~' expansion) for longer or 'full' (with '~' expansion) for even longer prompt display. Type: null or one of "short", "long", "full" Default: null Example: "short" Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # prompt.showReturnVal = ; # Set the prompt to display the return code along with an indicator for non-zero return codes. This is not supported by all prompts. Type: null or boolean Default: null Example: true Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   prompt.theme =
    #     "steeef"; # Set the prompt theme to load. Setting it to 'random' loads a random theme. Auto set to 'off' on dumb terminals. Type: null or string Default: "sorin" Example: "pure" Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # python.virtualenvAutoSwitch = ; # Auto switch to Python virtualenv on directory change. Type: null or boolean Default: null Example: true Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # python.virtualenvInitialize = ; # Automatically initialize virtualenvwrapper if pre-requisites are met. Type: null or boolean Default: null Example: true Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # ruby.chrubyAutoSwitch = ; # Auto switch the Ruby version on directory change. Type: null or boolean Default: null Example: true Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # screen.autoStartLocal = ; # Auto start a session when Zsh is launched in a local terminal. Type: null or boolean Default: null Example: true Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # screen.autoStartRemote = ; # Auto start a session when Zsh is launched in a SSH connection. Type: null or boolean Default: null Example: true Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   ssh.identities = [ "id_rsa" ];
    #   # syntaxHighlighting.highlighters = ; # Set syntax highlighters. By default, only the main highlighter is enabled. Type: list of string Default: [ ] Example: [ "main" "brackets" "pattern" "line" "cursor" "root" ] Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # syntaxHighlighting.pattern = ; # Set syntax pattern styles. Type: attribute set of string Default: { } Example: { rm*-rf* = "fg=white,bold,bg=red"; } Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # syntaxHighlighting.styles = ; # Set syntax highlighting styles. Type: attribute set of string Default: { } Example: { builtin = "bg=blue"; command = "bg=blue"; function = "bg=blue"; } Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   terminal.autoTitle = true;
    #   # terminal.multiplexerTitleFormat = ; # Set the multiplexer title format. Type: null or string Default: null Example: "%s" Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # terminal.tabTitleFormat = ; # Set the tab title format. Type: null or string Default: null Example: "%m: %s" Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # terminal.windowTitleFormat = ; # Set the window title format. Type: null or string Default: null Example: "%n@%m: %s" Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # tmux.autoStartLocal = ; # Auto start a session when Zsh is launched in a local terminal. Type: null or boolean Default: null Example: true Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # tmux.autoStartRemote = ; # Auto start a session when Zsh is launched in a SSH connection. Type: null or boolean Default: null Example: true Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # tmux.defaultSessionName = ; # Set the default session name. Type: null or string Default: null Example: "YOUR DEFAULT SESSION NAME" Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # tmux.itermIntegration = ; # Integrate with iTerm2. Type: null or boolean Default: null Example: true Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    #   # utility.safeOps = ; # Enabled safe options. This aliases cp, ln, mv and rm so that they prompt before deleting or overwriting files. Set to 'no' to disable this safer behavior. Type: null or boolean Default: null Example: true Declared by: <home-manager/modules/programs/zsh/prezto.nix>
    # };
  };
}
