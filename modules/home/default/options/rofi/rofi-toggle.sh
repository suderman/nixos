#!/usr/bin/env bash
if $(pidof -q rofi >/dev/null); then
  kill $(pidof -s rofi)
else
  if [[ -n "${@-}" ]]; then
    rofi "${@}"
  fi
fi
