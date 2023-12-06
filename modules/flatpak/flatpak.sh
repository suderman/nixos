#!/usr/bin/env bash

# Wait until network is up
until ping dl.flathub.org -c1 -q >/dev/null; do :; done

# Add flathub remotes if they doesn't yet exist
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists flathub-beta https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo
