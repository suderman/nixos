if [[ "${TERM-}" == xterm-256color && ( -n "${SSH_TTY-}" || "${COLORTERM-}" == truecolor ) ]]; then
  export TERM=xterm-direct2
elif [[ "${TERM-}" == tmux-256color && "${COLORTERM-}" == truecolor ]]; then
  export TERM=tmux-direct
fi
