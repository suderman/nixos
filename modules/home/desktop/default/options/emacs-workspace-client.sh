#!/usr/bin/env bash
# Called by the packaged em launcher. All tools and EMACS_CLIENT/EMACS_SERVER
# are supplied by its Nix wrapper.
set -euo pipefail

mode=--tty
if [[ ${1-} == --gui ]]; then
  mode=--create-frame
  shift
fi

params=
identity=
if [[ -n ${TMUX_PANE-}${TMUX-} ]]; then
  [[ -n ${TMUX_PANE-} && -n ${TMUX-} ]] || {
    echo 'em: tmux pane or socket is missing' >&2; exit 1;
  }
  socket=${TMUX%%,*}
  [[ -S $socket ]] || { echo "em: tmux socket is unavailable: $socket" >&2; exit 1; }
  session=$(tmux display-message -p -t "$TMUX_PANE" '#{session_id}') || {
    echo "em: cannot resolve tmux session for pane $TMUX_PANE" >&2; exit 1;
  }
  [[ -n $session ]] || { echo "em: tmux returned no session for $TMUX_PANE" >&2; exit 1; }
  identity="tmux:$socket:$session"
  params=$(jq -nr --arg pane "$TMUX_PANE" --arg socket "$TMUX" \
    '"((edger-tmux-pane-id . \($pane|tojson)) (edger-tmux-socket . \($socket|tojson)))"')
elif [[ ${HERDR_ENV-} == 1 || -n ${HERDR_PANE_ID-}${HERDR_SOCKET_PATH-}${HERDR_WORKSPACE_ID-} ]]; then
  [[ -n ${HERDR_PANE_ID-} && -n ${HERDR_SOCKET_PATH-} && -S $HERDR_SOCKET_PATH ]] || {
    echo 'em: Herdr pane or socket is missing' >&2; exit 1;
  }
  pane=$(herdr pane current --current) || { echo 'em: cannot resolve current Herdr pane' >&2; exit 1; }
  workspace=$(jq -er '.result.pane.workspace_id | select(type == "string" and length > 0)' <<<"$pane") || {
    echo 'em: Herdr returned no workspace for calling pane' >&2; exit 1;
  }
  pane_id=$(jq -er '.result.pane.pane_id | select(type == "string" and length > 0)' <<<"$pane") || {
    echo 'em: Herdr returned no calling pane ID' >&2; exit 1;
  }
  socket=$HERDR_SOCKET_PATH
  identity="herdr:$socket:$workspace"
  params=$(jq -nr --arg pane "$pane_id" --arg socket "$socket" \
    '"((edger-herdr-pane-id . \($pane|tojson)) (edger-herdr-socket-path . \($socket|tojson)))"')
fi

if [[ -z $identity ]]; then
  exec "$EMACS_CLIENT" "$mode" "$@"
fi

# Herdr and tmux reuse short IDs when their servers restart. Socket birth time
# and boot ID keep a surviving Emacs daemon from being mistaken for a new one.
birth=$(stat -Lc '%d:%i:%w' -- "$socket")
[[ $birth != *:- ]] || { echo "em: socket creation time unavailable: $socket" >&2; exit 1; }
boot=$(< /proc/sys/kernel/random/boot_id)
name=em-$(printf '%s\n' "$boot:$birth:$identity" | sha256sum)
name=${name:0:27}

if ! "$EMACS_CLIENT" -s "$name" -e t >/dev/null 2>&1; then
  runtime=${XDG_RUNTIME_DIR:?em: XDG_RUNTIME_DIR is required}
  exec 9>"$runtime/$name.lock"
  flock 9
  if ! "$EMACS_CLIENT" -s "$name" -e t >/dev/null 2>&1; then
    # State includes history, autosaves, backups, and Custom. Package data stays
    # shared, while the mutable per-daemon state lives outside the config tree.
    export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/emacs-workspaces/$name"
    install -d -m 700 "$XDG_STATE_HOME"
    if ! "$EMACS_SERVER" --daemon="$name" >"$XDG_STATE_HOME/startup.log" 2>&1; then
      cat "$XDG_STATE_HOME/startup.log" >&2
      exit 1
    fi
  fi
  flock -u 9
  exec 9>&-
fi

if [[ $mode == --tty ]]; then
  exec "$EMACS_CLIENT" -s "$name" "$mode" -F "$params" "$@"
fi
exec "$EMACS_CLIENT" -s "$name" "$mode" "$@"
