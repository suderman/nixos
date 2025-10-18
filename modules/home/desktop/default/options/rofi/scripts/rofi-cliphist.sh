#!/usr/bin/env bash

if [[ -n "${1-}" ]]; then
  printf %s "${1-}" | cliphist decode | wl-copy
else
  cliphist list
fi
