#!/usr/bin/env bash

# Resemble sv command from runit
if [[ "${1-}" == "log" ]]; then

  # Follow logs
  if [[ "${2-}" == "-f" ]]; then
    if [[ -z "${3-}" ]]; then
      [ $EUID -eq 0 ] && command journalctl -f || command journalctl --user -f;
    else
      [ $EUID -eq 0 ] && command journalctl -fu ${@:3} || command journalctl --user -fu ${@:3};
    fi

  # All logs
  else
    if [[ -z "${2-}" ]]; then
      [ $EUID -eq 0 ] && command journalctl || command journalctl --user;
    else
      [ $EUID -eq 0 ] && command journalctl -u ${@:2} || command journalctl --user -u ${@:2};
    fi
  fi

# Control units
else
  [ $EUID -eq 0 ] && command systemctl ${@-} || command systemctl --user ${@-};
fi
