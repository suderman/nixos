set -euo pipefail
source "$1"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
hyprpicker() { exec sleep 60; }
slurp() { [[ ${cancel:-0} == 0 ]] && printf '10,10 50x50\n'; }
grim() { printf image; }
tesseract() { printf 'SCREEN_TEXT_TEST'; }
zbarimg() { [[ ${empty:-0} == 0 ]] && printf 'PRIVATE_QR_TEST'; }
wl-copy() {
  printf '%s\n' "$*" >"$work/args"
  command cat >"$work/clipboard"
}
notify-send() { printf '%s\n' "$*" >>"$work/notifications"; }
printscreen_read qr
[[ $(<"$work/clipboard") == PRIVATE_QR_TEST ]]
grep -q -- --sensitive "$work/args"
! grep -q PRIVATE_QR_TEST "$work/notifications"
printscreen_read text
[[ $(<"$work/clipboard") == SCREEN_TEXT_TEST ]]
! grep -q -- --sensitive "$work/args"
cancel=1 printscreen_read qr
[[ $(<"$work/clipboard") == SCREEN_TEXT_TEST ]]
if empty=1 printscreen_read qr; then exit 1; fi
[[ $(<"$work/clipboard") == SCREEN_TEXT_TEST ]]
printf 'screen capture modes, private hint and cancellation: passed\n'
