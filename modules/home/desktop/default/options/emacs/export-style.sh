# Syncthing needs portable contents, not a /nix/store symlink. Rename atomically.
set -eu
dest="$HOME/org/.generated/emacs/style.el"
mkdir -p "$(dirname "$dest")"
if [ ! -L "$dest" ] && cmp -s "$style" "$dest"; then
  exit 0
fi
tmp=$(mktemp "$dest.XXXXXX")
trap 'rm -f "$tmp"' EXIT
cp "$style" "$tmp"
chmod 644 "$tmp"
mv -fT "$tmp" "$dest"
