# Absolute laptop brightness uses the same device and OSD as lightctl steps.
mediactl_brightness() {
  local operation="${1-}" value="${2-}"
  case "$operation" in
  get)
    if [ "$#" -ne 1 ]; then return 64; fi
    ;;
  set)
    if [ "$#" -ne 2 ] || [[ ! $value =~ ^([1-9][0-9]?|100)$ ]]; then
      echo 'Brightness must be an integer from 1 to 100' >&2
      return 64
    fi
    ;;
  *) return 64 ;;
  esac

  local info device class current percent maximum
  info="$(brightnessctl --class=backlight --machine-readable info 2>/dev/null)" || return 1
  IFS=, read -r device class current percent maximum <<<"$info"
  if [[ -z $device || $class != backlight || ! $percent =~ ^([0-9]|[1-9][0-9]|100)%$ ]]; then
    return 1
  fi
  if [ "$operation" = get ]; then
    printf '%s\n' "${percent%\%}"
  else
    lightctl -d -D "$device" set "$value"
  fi
}
