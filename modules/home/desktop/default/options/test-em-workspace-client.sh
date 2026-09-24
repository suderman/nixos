#!/usr/bin/env bash
set -euo pipefail
unset HERDR_ENV TMUX TMUX_PANE
cd "$(dirname "$0")"
tmp=$(mktemp -d)
export XDG_RUNTIME_DIR=$tmp XDG_STATE_HOME=$tmp/state EMACS_CLIENT=$tmp/client EMACS_SERVER=$tmp/server
mkdir "$tmp/bin"
export PATH="$tmp/bin:$PATH"

# A real Unix socket supplies the instance identity; mock only Herdr's pane API.
cat >"$tmp/unix-listener.py" <<'PY'
import socket, sys, time
sock = socket.socket(socket.AF_UNIX)
sock.bind(sys.argv[1])
sock.listen()
time.sleep(30)
PY
python3 "$tmp/unix-listener.py" "$tmp/socket" &
socket_pid=$!
trap 'kill "$socket_pid" 2>/dev/null || true; rm -rf "$tmp"' EXIT
for ((attempt=0; attempt<50; attempt++)); do
  [[ -S $tmp/socket ]] && break
  sleep 0.02
done
[[ -S $tmp/socket ]]

cat >"$tmp/bin/herdr" <<'SH'
#!/usr/bin/env bash
case $HERDR_PANE_ID in
  old|moved) ws=w2; pane=moved;;
  other) ws=w3; pane=other;;
  broken) ws=w4; pane=broken;;
  *) exit 1;;
esac
printf '{"result":{"pane":{"pane_id":"%s","workspace_id":"%s"}}}\n' "$pane" "$ws"
SH
cat >"$tmp/client" <<'SH'
#!/usr/bin/env bash
if [[ $* == *'-e t'* ]]; then
  [[ -e "$XDG_RUNTIME_DIR/server-$2" ]]
  exit
fi
printf '%s\n' "$*" >>"$XDG_RUNTIME_DIR/clients"
SH
cat >"$tmp/server" <<'SH'
#!/usr/bin/env bash
printf 'daemon startup message\n' >&2
if [[ ${EMACS_SERVER_FAIL-} == 1 ]]; then
  printf 'daemon startup failed\n' >&2
  exit 7
fi
sleep 0.1
printf '%s\n' "$*" >>"$XDG_RUNTIME_DIR/servers"
touch "$XDG_RUNTIME_DIR/server-${1#--daemon=}"
SH
chmod +x "$tmp/bin/herdr" "$tmp/client" "$tmp/server"
export HERDR_SOCKET_PATH=$tmp/socket HERDR_PANE_ID=old HERDR_WORKSPACE_ID=w1

# Two simultaneous calls start once. Moved pane resolves w2, not stale w1.
bash ./emacs-workspace-client.sh --gui --no-wait 'file with spaces' >"$tmp/first.out" 2>"$tmp/first.err" &
first=$!
bash ./emacs-workspace-client.sh --gui --no-wait 'another file' >"$tmp/second.out" 2>"$tmp/second.err" &
second=$!
wait "$first" "$second"
[[ $(wc -l <"$tmp/servers") == 1 ]]
[[ $(wc -l <"$tmp/clients") == 2 ]]
name=$(awk '{print $2}' "$tmp/clients" | sort -u)
[[ $(wc -l <<<"$name") == 1 ]]
[[ ! -s $tmp/first.out && ! -s $tmp/first.err && ! -s $tmp/second.out && ! -s $tmp/second.err ]]
grep -q 'daemon startup message' "$tmp/state/emacs-workspaces/$name/startup.log"
[[ $(grep -c -- '--create-frame' "$tmp/clients") == 2 ]]
grep -q 'file with spaces' "$tmp/clients"
bash ./emacs-workspace-client.sh
[[ $(tail -1 "$tmp/clients") == *' --tty -F '*'.' ]]

HERDR_PANE_ID=moved bash ./emacs-workspace-client.sh --no-wait '+2:3' 'file with spaces'
[[ $(wc -l <"$tmp/servers") == 1 ]]
grep -q 'edger-herdr-pane-id . "moved"' "$tmp/clients"
grep -q '+2:3 file with spaces' "$tmp/clients"
HERDR_PANE_ID=other bash ./emacs-workspace-client.sh --gui
[[ $(tail -1 "$tmp/clients") == *' --create-frame .' ]]
[[ $(wc -l <"$tmp/servers") == 2 ]]
if HERDR_PANE_ID=gone bash ./emacs-workspace-client.sh --gui 2>"$tmp/error"; then
  echo 'unknown Herdr pane unexpectedly succeeded' >&2; exit 1
fi
grep -q 'cannot resolve current Herdr pane' "$tmp/error"
if EMACS_SERVER_FAIL=1 HERDR_PANE_ID=broken bash ./emacs-workspace-client.sh --gui >"$tmp/fail.out" 2>"$tmp/fail.err"; then
  echo 'failed daemon startup unexpectedly succeeded' >&2; exit 1
fi
grep -q 'daemon startup failed' "$tmp/fail.err"
if env -u HERDR_PANE_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH HERDR_ENV=1 \
    bash ./emacs-workspace-client.sh --gui 2>"$tmp/error"; then
  echo 'unresolved Herdr environment unexpectedly fell back' >&2; exit 1
fi
grep -q 'Herdr pane or socket is missing' "$tmp/error"
if env -u HERDR_PANE_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH \
    TMUX="$tmp/socket,1,0" bash ./emacs-workspace-client.sh --gui 2>"$tmp/error"; then
  echo 'unresolved tmux environment unexpectedly fell back' >&2; exit 1
fi
grep -q 'tmux pane or socket is missing' "$tmp/error"

# Reusing w2 on a new server at the same socket path must not reuse its daemon.
kill "$socket_pid"
wait "$socket_pid" 2>/dev/null || true
rm "$tmp/socket"
python3 "$tmp/unix-listener.py" "$tmp/socket" &
socket_pid=$!
for ((attempt=0; attempt<50; attempt++)); do
  [[ -S $tmp/socket ]] && break
  sleep 0.02
done
HERDR_PANE_ID=moved bash ./emacs-workspace-client.sh --gui
[[ $(wc -l <"$tmp/servers") == 3 ]]

env -u HERDR_PANE_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH bash ./emacs-workspace-client.sh --gui
[[ $(wc -l <"$tmp/servers") == 3 ]]
[[ $(tail -1 "$tmp/clients") == '--create-frame .' ]]
env -u HERDR_PANE_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH \
  bash ./emacs-workspace-client.sh --gui --no-wait 'explicit file'
[[ $(tail -1 "$tmp/clients") == '--create-frame --no-wait explicit file' ]]
echo 'em workspace identity, movement, isolation, startup race, GUI and fallback: ok'
