{
  config,
  lib,
  pkgs,
  perSystem,
  flake,
  ...
}: let
  inherit (lib) mkIf mkOption;

  cfg = config.programs.herdr;
  tomlFormat = pkgs.formats.toml {};

  edger = pkgs.self.mkScript {
    name = "edger";
    path = [cfg.package pkgs.jq pkgs.procps];
    text = builtins.readFile "${flake.inputs.edger}/bin/edger";
  };

  # wrapped herdr to own workspace emacs servers
  herdr = pkgs.self.mkScript {
    name = "herdr";
    path = with pkgs; [coreutils gawk gnugrep procps];
    text =
      # bash
      ''
        if [[ $# -eq 2 && $1 == server && $2 == stop ]]; then
          socket=$(${lib.getExe cfg.package} status server | awk '$1 == "socket:" {print $2}')
          [[ -n $socket ]] || { echo 'herdr: cannot find server socket; refusing to stop' >&2; exit 1; }

          # The pane exits during stop, so terminate its detached Emacs daemons first.
          for pid in $(pgrep -u "$(id -u)" -f -- '--daemon=em-' || true); do
            grep -zFxq "HERDR_SOCKET_PATH=$socket" "/proc/$pid/environ" 2>/dev/null || continue
            grep -zEq '^(TMUX|TMUX_PANE)=' "/proc/$pid/environ" 2>/dev/null && continue
            grep -zEq '^--daemon=em-[[:xdigit:]]{24}$' "/proc/$pid/cmdline" 2>/dev/null || continue
            kill "$pid" 2>/dev/null || true
          done
        fi

        exec ${lib.getExe cfg.package} "$@"
      '';
  };
in {
  # Avoid duplicate options when release-26.11 imports the upstream module.
  disabledModules = ["programs/herdr.nix"];

  options.programs.herdr = {
    enable = lib.mkEnableOption "Herdr";

    package = mkOption {
      type = lib.types.nullOr lib.types.package;
      default = perSystem.herdr.default;
      description = "The Herdr package to use.";
    };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = {};
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/herdr/config.toml`.
        See <https://herdr.dev/docs/configuration/> for the full list of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [herdr edger];

    # Herdr stores mutable local data beside Home Manager's generated config.toml.
    persist.storage.directories = [".config/herdr"];

    # Home Manager owns config.toml, so Herdr cannot record onboarding itself.
    programs.herdr.settings = {
      onboarding = false;
      ui = {
        toast.delivery = "herdr";
        sidebar.spaces.rows = [["state_icon" "workspace" "branch"]];
        prompt_new_tab_name = false;
      };

      keys = {
        prefix = "alt+z";

        new_workspace = "alt+shift+n";
        rename_workspace = "prefix+period";
        workspace_picker = "alt+a";
        detach = "prefix+d";

        new_tab = "alt+shift+t";
        rename_tab = "prefix+comma";
        previous_tab = "prefix+[";
        next_tab = "prefix+]";
        move_tab_previous = "prefix+{";
        move_tab_next = "prefix+}";
        copy_mode = "prefix+m";

        split_horizontal = "prefix+u";
        split_vertical = "prefix+i";
        close_pane = "alt+shift+w";
        last_pane = "prefix+o";

        focus_pane_left = "prefix+h";
        focus_pane_down = "prefix+j";
        focus_pane_up = "prefix+k";
        focus_pane_right = "prefix+l";

        command = let
          modifier = "alt";
          binds.direction = {
            left = "h";
            down = "j";
            up = "k";
            right = "l";
          };
          binds.action = {
            horizontal = "u";
            vertical = "i";
            close = "w";
          };
        in
          lib.mapAttrsToList (direction: letter: {
            key = "${modifier}+${letter}";
            type = "shell";
            command = "${lib.getExe edger} ${direction} ${modifier}+${letter}";
            description = "Navigate ${direction} across editor, pane, and outer layer";
          })
          binds.direction
          ++ lib.mapAttrsToList (direction: letter: {
            key = "${modifier}+shift+${letter}";
            type = "shell";
            command = "${lib.getExe edger} resize ${direction} ${modifier}+shift+${letter}";
            description = "Navigate ${direction} across editor, pane, and outer layer";
          })
          binds.direction
          ++ lib.mapAttrsToList (action: letter: {
            key = "${modifier}+${letter}";
            type = "shell";
            command = "${lib.getExe edger} ${action} ${modifier}+${letter}";
            description = "Edger ${action}";
          })
          binds.action;
      };
    };

    xdg.configFile."herdr/config.toml" = mkIf (cfg.settings != {}) {
      source = tomlFormat.generate "herdr-config.toml" cfg.settings;
      onChange = "${cfg.package} server reload-config || true";
    };

    # install herdr plugins
    home.activation.herdr = let
      herdr = lib.getExe cfg.package;
    in
      lib.hm.dag.entryAfter ["linkGeneration"]
      # bash
      ''
        export PATH=${lib.makeBinPath [pkgs.git]}:$PATH

        # https://github.com/horn553/herdr-ntfy
        $DRY_RUN_CMD ${herdr} plugin install horn553/herdr-ntfy --yes
        config_dir="$(${herdr} plugin config-dir horn553.herdr-ntfy)"
        install -m 600 /dev/null "$config_dir/.env"
        cat > "$config_dir/.env" <<'EOF'
        NTFY_URL=https://ntfy.hub/herdr
        NTFY_TITLE=Herdr
        NTFY_LINES=12
        NTFY_TOKEN=
        COLLIE_URL=
        EOF

        # https://github.com/qu8n/herdr-automatic-rename
        $DRY_RUN_CMD ${herdr} plugin install qu8n/herdr-automatic-rename --yes
        mkdir -p "${config.xdg.configHome}/herdr-automatic-rename"
        cat > "${config.xdg.configHome}/herdr-automatic-rename/config.sh" <<'EOF'
        HOST_PREFIX=0
        TAB_CONTEXT=1
        SHOW_BRANCH=1
        AGENT_TITLE=1
        TITLE_STYLE=task # name_and_task
        ICONS_ENABLED=1
        EOF
      '';

    programs.zsh.initContent = lib.mkAfter ''
      for _f in ${config.xdg.configHome}/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.zsh(N); do
        source $_f; break
      done
    '';
  };
}
