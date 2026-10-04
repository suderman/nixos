#!/usr/bin/env bash
# Forced command for a dedicated backup-host key. No guest-controlled destination.
set -euo pipefail
export LC_ALL=C
cd /mnt/main
command=${SSH_ORIGINAL_COMMAND-}
case "$command" in
list)
  find snapshots -maxdepth 1 -type d -name 'storage.*' -printf '%f\n' | sort
  ;;
send\ storage.*)
  snapshot=${command#send }
  [[ $snapshot =~ ^storage\.[0-9]{8}T[0-9]{4}$ ]] || exit 1
  test ! -L "snapshots/$snapshot"
  btrfs property get -ts "snapshots/$snapshot" ro | grep -qx 'ro=true'
  exec btrfs send "snapshots/$snapshot"
  ;;
acknowledge)
  touch storage/etc/dot/backup-success
  ;;
*)
  echo 'Allowed commands: list, send storage.YYYYMMDDTHHMM, acknowledge' >&2
  exit 1
  ;;
esac
