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

  # Org links to agent sessions; jump expects Hyprland and kitty on the desktop.
  herdrLink = pkgs.self.mkScript {
    name = "herdr-link";
    path = with pkgs; [cfg.package jq openssh procps gawk gnugrep gnused util-linux];
    text =
      # bash
      ''
        # Stamp and follow Org links to Herdr agent sessions.
        #
        #   herdr-link stamp        print an Org link for the calling Herdr pane
        #   herdr-link jump LINK    focus the pane for LINK, resuming the session if needed
        #
        # LINK is [herdr:]HOST/AGENT:SESSION[@PANE]. SESSION is the Claude session ID or
        # the Pi session UUID. PANE is only a fallback hint; the session finds the pane.

        die() {
          echo "herdr-link: $*" >&2
          exit 1
        }

        stamp() {
          [[ -n ''${HERDR_PANE_ID:-} ]] || die "not in a Herdr pane"
          herdr pane get "$HERDR_PANE_ID" | jq -er --arg host "$(</proc/sys/kernel/hostname)" '
            .result.pane as $p
            | ($p.agent_session // error("no agent session in this pane")) as $s
            | ($s.value | if $s.agent == "pi" then capture("_(?<id>[0-9a-f-]{36})\\.jsonl$").id else . end) as $id
            | "[[herdr:\($host)/\($s.agent):\($id)@\($p.pane_id)][\($host) · \($s.agent) · \(now | strflocaltime("%Y-%m-%d %H:%M"))]]"'
        }

        # Run a command on the link's host, over ssh when it is not this one.
        on_host() {
          if [[ -z $remote ]]; then
            "$@"
          else
            ssh -o ConnectTimeout=5 "$host" "$(printf '%q ' "$@")"
          fi
        }

        # Find the session file on its host and set the directory and resume command.
        find_session() {
          local found
          found=$(on_host sh -s -- "$agent" "$session" <<'EOF'
        case $1 in
          claude) f=$(ls ~/.claude/projects/*/"$2".jsonl 2>/dev/null | head -n1) ;;
          pi) f=$(ls ~/.local/state/pi/sessions/*/*_"$2".jsonl ~/.pi/agent/sessions/*/*_"$2".jsonl 2>/dev/null | head -n1) ;;
        esac
        [ -n "$f" ] || exit 1
        printf '%s\n%s\n' "$(grep -m1 -o '"cwd":"[^"]*"' "$f" | cut -d'"' -f4)" "$f"
        EOF
          ) || die "session $agent:$session not found on $host"
          cwd=$(sed -n 1p <<<"$found")
          case $agent in
            claude) cmd="claude --resume $session" ;;
            pi) cmd="pi --session $(sed -n 2p <<<"$found")" ;;
          esac
        }

        # Raise the window running a Herdr client for this host. Fails if none exists.
        raise() {
          local pattern clients pid p window address workspace
          if [[ -z $remote ]]; then
            pattern='[^ ]*/?herdr( --session [^ ]+)?$'
          else
            pattern="[^ ]*/?herdr --remote $host( |$)"
          fi
          clients=$(hyprctl clients -j | jq -r '.[] | [.pid, .address, .workspace.name] | @tsv')
          for pid in $(ps -eo pid=,args= | sed -E 's/^ *//' | grep -E "^[0-9]+ ($pattern)" | cut -d' ' -f1); do
            p=$pid
            while [[ $p -gt 1 ]]; do
              window=$(awk -F'\t' -v p="$p" '$1 == p { print; exit }' <<<"$clients")
              if [[ -n $window ]]; then
                IFS=$'\t' read -r _ address workspace <<<"$window"
                hyprctl dispatch "hl.dsp.focus({ workspace = \"$workspace\" })" >/dev/null
                hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
                return 0
              fi
              p=$(ps -o ppid= -p "$p" | tr -d ' ')
            done
          done
          return 1
        }

        # Herdr sends focus commands to the client whose window was focused last, so
        # raise or open that window before focusing anything.
        show() {
          local launch=(herdr) i
          [[ -z $remote ]] || launch=(herdr --remote "$host" --remote-keybindings server)
          if ! raise; then
            # Clear Herdr's variables so a launch from inside a pane is not nested.
            setsid -f env -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID \
              kitty --class=Herdr "''${launch[@]}" >/dev/null 2>&1
            for i in {1..20}; do
              sleep 0.25
              raise && break
            done
            ((i < 20)) || die "no Herdr client window for $host"
            sleep 1
          fi
          sleep 0.3
        }

        jump() {
          local link=''${1#herdr:} rest target tab new cwd cmd
          pane=
          host=''${link%%/*}
          rest=''${link#*/}
          if [[ $rest == *@* ]]; then
            pane=''${rest##*@}
            rest=''${rest%@*}
          fi
          agent=''${rest%%:*}
          session=''${rest#*:}
          [[ $link == */* && $rest == *:* && -n $host && -n $agent && -n $session ]] || die "bad link: $1"
          remote=
          [[ $host == "$(</proc/sys/kernel/hostname)" ]] || remote=1

          target=$(on_host herdr agent list | jq -r --arg a "$agent" --arg s "$session" '
            first(.result.agents[] | select(.agent_session.agent == $a and (.agent_session.value | contains($s))) | .pane_id) // empty')
          if [[ -z $target && -n $pane ]]; then
            tab=$(on_host herdr pane get "$pane" 2>/dev/null | jq -r '.result.pane.tab_id // empty') || true
          fi
          [[ -n $target || -n ''${tab:-} ]] || find_session

          show
          if [[ -n $target ]]; then
            on_host herdr agent focus "$target" >/dev/null
          elif [[ -n ''${tab:-} ]]; then
            on_host herdr tab focus "$tab" >/dev/null
          else
            new=$(on_host herdr tab create --cwd "$cwd" --focus | jq -r .result.root_pane.pane_id)
            on_host herdr pane run "$new" "$cmd" >/dev/null
          fi
        }

        case ''${1:-} in
          stamp) stamp ;;
          jump) [[ $# -eq 2 ]] || die "usage: herdr-link jump LINK"; jump "$2" ;;
          *) die "usage: herdr-link stamp | herdr-link jump LINK" ;;
        esac
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
    home.packages = [herdr edger herdrLink];

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

    # Run the server at login so it survives reboots and closed clients. Clients
    # and the Org dispatcher attach to it.
    systemd.user.services.herdr = let
      # Skip when a client already started a server outside this unit.
      notRunning = pkgs.self.mkScript {
        name = "herdr-not-running";
        path = [cfg.package pkgs.gnugrep];
        text = ''
          status=$(herdr status server)
          ! grep -qx 'status: running' <<<"$status"
        '';
      };
    in {
      Unit = {
        Description = "Herdr server";
        After = ["graphical-session.target"];
        # Restarting kills every pane and agent; new versions wait for login.
        X-RestartIfChanged = false;
      };
      Service = {
        ExecCondition = lib.getExe notRunning;
        ExecStart = "${lib.getExe herdr} server";
        ExecStop = "${lib.getExe herdr} server stop";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    # Plugin downloads must not block Home Manager activation during boot.
    systemd.user.services.herdr-plugins = let
      herdr = lib.getExe cfg.package;
      installPlugins = pkgs.self.mkScript {
        name = "herdr-plugins";
        path = [pkgs.git pkgs.coreutils];
        text = ''
          export GIT_TERMINAL_PROMPT=0

          # https://github.com/horn553/herdr-ntfy
          ${herdr} plugin install horn553/herdr-ntfy --yes
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
          ${herdr} plugin install qu8n/herdr-automatic-rename --yes
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
      };
    in {
      Unit = {
        Description = "Install Herdr plugins";
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe installPlugins;
        Restart = "on-failure";
        RestartSec = 30;
      };
      Install.WantedBy = ["default.target"];
    };

    programs.zsh.initContent = lib.mkAfter ''
      for _f in ${config.xdg.configHome}/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.zsh(N); do
        source $_f; break
      done
    '';
  };
}
