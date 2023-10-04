#!/usr/bin/env bash

# Wait until network is up
until /run/wrappers/bin/ping flathub.org -c1 -q >/dev/null; do :; done

# Add flathub remote if it doesn't yet exist
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
