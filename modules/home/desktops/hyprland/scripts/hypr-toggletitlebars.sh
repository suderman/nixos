#!/usr/bin/env bash
enabled="$(hyprctl getoption plugin:hyprbars:enabled)"
if [[ $enabled == *1* ]]; then
  hyprctl keyword plugin:hyprbars:enabled false
else
  hyprctl keyword plugin:hyprbars:enabled true
fi
