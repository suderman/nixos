# Run in a subshell so selection cleanup cannot change the caller's traps.
printscreen_read() (
  set -euo pipefail
  local kind=$1 coords data freeze
  hyprpicker -r -z >/dev/null 2>&1 &
  freeze=$!
  trap 'kill "$freeze" 2>/dev/null || true; wait "$freeze" 2>/dev/null || true' EXIT
  sleep 0.15
  coords=$(slurp) || exit 0
  [[ -n $coords ]] || exit 0

  if [[ $kind == text ]]; then
    if ! data=$(grim -g "$coords" - | tesseract stdin stdout -l eng --psm 6 2>/dev/null); then
      notify-send 'Screen text' 'Could not read this region.'
      exit 1
    fi
  else
    if ! data=$(grim -g "$coords" - | zbarimg --quiet --raw -Sdisable -Sqrcode.enable - 2>/dev/null); then
      notify-send 'Screen QR' 'No QR code found in this region.'
      exit 1
    fi
  fi
  if [[ -z $data ]]; then
    notify-send 'Screen capture' 'No content found in this region.'
    exit 0
  fi
  # Cliphist honors the sensitive hint. Never log or display decoded QR data.
  if [[ $kind == qr ]]; then
    printf '%s' "$data" | wl-copy --type text/plain --sensitive
    notify-send 'Screen QR' 'Copied without clipboard history.'
  else
    printf '%s' "$data" | wl-copy --type text/plain
    notify-send 'Screen text' 'Copied to clipboard.'
  fi
)
