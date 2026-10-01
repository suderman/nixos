set -euo pipefail
image="" progress="" monitor=-1
for arg in "$@"; do
  case "$arg" in
  --image-resource=*) image=${arg#*=} ;;
  --progress=*) progress=${arg#*=} ;;
  --monitor=*) monitor=${arg#*=} ;;
  *)
    printf 'Unsupported media OSD argument: %s\n' "$arg" >&2
    exit 64
    ;;
  esac
done
image=${image%_dark}
case "$image" in
volume_muted | volume_low | volume_medium | volume_high | mic_muted | mic_unmuted | brightness_low | brightness_medium | brightness_high) ;;
*)
  printf 'Invalid media OSD image\n' >&2
  exit 64
  ;;
esac
[[ $progress =~ ^[0-9]+([.][0-9]+)?$ && $monitor =~ ^(-1|[0-9]+)$ ]] || {
  printf 'Invalid media OSD value\n' >&2
  exit 64
}
# Avizo's existing control scripts supply this interface. Replace only their
# renderer on mediactl's private PATH, not the control logic or global commands.
if ! @QS@ ipc -c @CONFIG@ call media-osd display "$image" "$progress" "$monitor"; then
  printf 'Media action applied, but Quickshell OSD is unavailable\n' >&2
  exit 1
fi
