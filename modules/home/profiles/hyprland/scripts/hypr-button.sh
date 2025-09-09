#!/usr/bin/env bash

# Get first argument (if set), otherwise cat contents of /run/keyd/button
btn="${1-$([[ -e /run/keyd/button ]] && cat /run/keyd/button)}"

# Echo value of right, middle, or left (default)
case "$btn" in
right) echo right ;;
middle) echo middle ;;
*) echo left ;;
esac
