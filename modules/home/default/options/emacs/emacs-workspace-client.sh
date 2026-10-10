#!/usr/bin/env bash
# Called by the packaged em launcher. All tools and EMACS_CLIENT/EMACS_SERVER
# are supplied by its Nix wrapper.
set -euo pipefail

# Herdr and tmux reuse short IDs when their servers restart. Socket birth time
# and boot ID keep a surviving Emacs daemon from being mistaken for a new one.
daemon_name() {
  local socket=$1 identity=$2 birth boot hash
  birth=$(stat -Lc '%d:%i:%w' -- "$socket")
  [[ $birth != *:- ]] || {
    echo "em: socket creation time unavailable: $socket" >&2
    return 1
  }
  boot=$(</proc/sys/kernel/random/boot_id)
  hash=$(printf '%s\n' "$boot:$birth:$identity" | sha256sum)
  echo "em-${hash:0:24}"
}

# Nothing is left to prompt in, so auto-save unsaved buffers before exiting.
# Only workspace daemons qualify; an empty name would reach the default server.
stop_daemon() {
  [[ $1 == em-* ]] || return 0
  "$EMACS_CLIENT" -s "$1" -e '(progn (do-auto-save t) (kill-emacs))' >/dev/null 2>&1 || true
}

case ${1-} in
--stop-tmux)
  # tmux session-closed hook: SOCKET SESSION_ID
  name=$(daemon_name "$2" "tmux:$2:$3")
  stop_daemon "$name"
  exit
  ;;
--watch-tmux)
  # tmux runs no hook when its last pane exits, so follow the server: PID NAME
  tail --pid="$2" -s 10 -f /dev/null
  stop_daemon "$3"
  exit
  ;;
--herdr-plugin)
  socket=${HERDR_SOCKET_PATH:?em: HERDR_SOCKET_PATH is required}
  case ${HERDR_PLUGIN_EVENT-} in
  workspace.closed)
    name=$(daemon_name "$socket" "herdr:$socket:${HERDR_WORKSPACE_ID:?em: HERDR_WORKSPACE_ID is required}")
    stop_daemon "$name"
    ;;
  startup)
    # A new server socket renames every workspace's daemon, so stop daemons
    # left by an earlier server. List daemons before workspaces: a daemon
    # started meanwhile belongs to a workspace that is already listed.
    pids=$(pgrep -u "$(id -u)" -f -- '--daemon=em-' || true)
    workspaces=$(herdr workspace list | jq -r '.result.workspaces[].workspace_id')
    keep=' '
    for workspace in $workspaces; do
      name=$(daemon_name "$socket" "herdr:$socket:$workspace")
      keep+="$name "
    done
    for pid in $pids; do
      grep -zFxq "HERDR_SOCKET_PATH=$socket" "/proc/$pid/environ" 2>/dev/null || continue
      grep -zEq '^(TMUX|TMUX_PANE)=' "/proc/$pid/environ" 2>/dev/null && continue
      name=$(grep -zoE '^--daemon=em-[[:xdigit:]]{24}$' "/proc/$pid/cmdline" 2>/dev/null | tr -d '\0') || continue
      name=${name#--daemon=}
      [[ $keep == *" $name "* ]] || stop_daemon "$name"
    done
    ;;
  esac
  exit
  ;;
esac

mode=--tty
if [[ ${1-} == --gui ]]; then
  mode=--create-frame
  shift
fi
[[ $# -gt 0 ]] || set -- .

params=
identity=
server_pid=
if [[ -n ${TMUX_PANE-}${TMUX-} ]]; then
  [[ -n ${TMUX_PANE-} && -n ${TMUX-} ]] || {
    echo 'em: tmux pane or socket is missing' >&2
    exit 1
  }
  socket=${TMUX%%,*}
  [[ -S $socket ]] || {
    echo "em: tmux socket is unavailable: $socket" >&2
    exit 1
  }
  pane=$(tmux display-message -p -t "$TMUX_PANE" '#{session_id} #{pid}') || {
    echo "em: cannot resolve tmux session for pane $TMUX_PANE" >&2
    exit 1
  }
  read -r session server_pid <<<"$pane"
  [[ -n $session ]] || {
    echo "em: tmux returned no session for $TMUX_PANE" >&2
    exit 1
  }
  identity="tmux:$socket:$session"
  params=$(jq -nr --arg pane "$TMUX_PANE" --arg socket "$TMUX" \
    '"((edger-tmux-pane-id . \($pane|tojson)) (edger-tmux-socket . \($socket|tojson)))"')
elif [[ ${HERDR_ENV-} == 1 || -n ${HERDR_PANE_ID-}${HERDR_SOCKET_PATH-}${HERDR_WORKSPACE_ID-} ]]; then
  [[ -n ${HERDR_PANE_ID-} && -n ${HERDR_SOCKET_PATH-} && -S $HERDR_SOCKET_PATH ]] || {
    echo 'em: Herdr pane or socket is missing' >&2
    exit 1
  }
  pane=$(herdr pane current --current) || {
    echo 'em: cannot resolve current Herdr pane' >&2
    exit 1
  }
  workspace=$(jq -er '.result.pane.workspace_id | select(type == "string" and length > 0)' <<<"$pane") || {
    echo 'em: Herdr returned no workspace for calling pane' >&2
    exit 1
  }
  pane_id=$(jq -er '.result.pane.pane_id | select(type == "string" and length > 0)' <<<"$pane") || {
    echo 'em: Herdr returned no calling pane ID' >&2
    exit 1
  }
  socket=$HERDR_SOCKET_PATH
  identity="herdr:$socket:$workspace"
  params=$(jq -nr --arg pane "$pane_id" --arg socket "$socket" \
    '"((edger-herdr-pane-id . \($pane|tojson)) (edger-herdr-socket-path . \($socket|tojson)))"')
fi

# Outside a multiplexer, use the default daemon. Its systemd user service
# normally runs it; start it here when the service has not.
name=server
if [[ -n $identity ]]; then
  name=$(daemon_name "$socket" "$identity")
fi

if ! "$EMACS_CLIENT" -s "$name" -e t >/dev/null 2>&1; then
  runtime=${XDG_RUNTIME_DIR:?em: XDG_RUNTIME_DIR is required}
  exec 9>"$runtime/$name.lock"
  flock 9
  if ! "$EMACS_CLIENT" -s "$name" -e t >/dev/null 2>&1; then
    log=${XDG_STATE_HOME:-$HOME/.local/state}/emacs/startup.log
    if [[ $name != server ]]; then
      # State includes history, autosaves, backups, and Custom. Package data stays
      # shared, while the mutable per-daemon state lives outside the config tree.
      export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/emacs-workspaces/$name"
      log=$XDG_STATE_HOME/startup.log
    fi
    install -d -m 700 "${log%/*}"
    if ! "$EMACS_SERVER" --daemon="$name" >"$log" 2>&1; then
      cat "$log" >&2
      exit 1
    fi
    if [[ -n $server_pid ]]; then
      setsid -f "$0" --watch-tmux "$server_pid" "$name" </dev/null >/dev/null 2>&1 9>&-
    fi
  fi
  flock -u 9
  exec 9>&-
fi

if [[ $mode == --tty && -n $params ]]; then
  exec "$EMACS_CLIENT" -s "$name" "$mode" -F "$params" "$@"
fi
exec "$EMACS_CLIENT" -s "$name" "$mode" "$@"
