#! /usr/bin/env bash
set -euo pipefail

# Pretty output
gum_exit() { gum style --foreground=196 "✖ $*" && return 1; }
gum_warn() { gum style --foreground=124 "✖ $*"; }
gum_info() { gum style --foreground=29 "➜ $*"; }
gum_head() { gum style --foreground=99 "$*"; }
gum_show() { gum style --foreground=177 "    $*"; }

# If PRJ_ROOT is set, change to that directory
[[ -n ${PRJ_ROOT-} ]] && cd "$PRJ_ROOT"

secrets_dir="${AGENIX_SECRETS_DIR:-secrets}"
runtime_dir="${AGENIX_RUNTIME_DIR:-/tmp}"
identity_file="$runtime_dir/id_age"
previous_identity_file="$runtime_dir/id_age_"
rotation_marker="${IDENTITY_ROTATION_MARKER:-$secrets_dir/rotation/ACTIVE}"

identity_rotation_guard() {
  if [[ ${IDENTITY_ROTATION_ALLOW:-0} != "1" && -e $rotation_marker ]]; then
    gum_exit "Identity rotation is active; use the managed rotation workflow"
  fi
}

agenix_rotation_guard_command() {
  local cmd="${1:-}"
  shift || true

  case "$cmd" in
  update-masterkeys)
    identity_rotation_guard
    ;;
  rekey)
    local arg
    for arg in "$@"; do
      if [[ $arg == "-a" || $arg == "--all" ]]; then
        identity_rotation_guard
      fi
    done
    ;;
  esac
}

# ---------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------
main() {

  case "${1:-}" in
  import | i)
    agenix_import
    exit 0
    ;;
  unlock | u)
    agenix_unlock "${2:-}"
    exit 0
    ;;
  lock | l)
    agenix_lock
    exit 0
    ;;
  hex | h)
    agenix_hex "${2:-}"
    exit 0
    ;;
  verify | v)
    agenix_verify "${2:-}"
    exit 0
    ;;
  "" | --help | -h | help)
    agenix --help "$@" || true
    agenix_help
    exit 0
    ;;
  *)
    agenix_rotation_guard_command "$@"
    agenix_unlock quiet
    agenix "$@"
    ;;
  esac

}

# Display extended commands with agenix help
agenix_help() {
  cat <<EOF

EXTENDED COMMANDS:
  import                  Bootstrap or recover the existing master identity
  unlock                  Unlock secrets/id_age.age to /tmp/id_age
  lock                    Remove temporary age identity from /tmp/id_age
  hex [--check]           Output the root hex, or validate its canonical form
  verify [DIR]            Verify match in directory's id_age & id_age.pub
EOF
}

# Remove temporary import files and restore old artifacts after a failed commit.
agenix_import_cleanup() {
  local status="$1"
  trap - EXIT HUP INT TERM

  if [[ ${import_committing-} == "true" && ${import_committed-} != "true" ]]; then
    local target backup existed
    for target in id_age.age id_age.pub hex.age; do
      backup="$import_work_dir/$target"
      existed="import_had_${target//./_}"
      if [[ ${!existed} == "true" ]]; then
        cp -p "$backup" "$secrets_dir/$target"
      else
        rm -f "$secrets_dir/$target"
      fi
    done
  fi

  rm -rf "${import_work_dir-}"
  rm -f "${import_identity_tmp-}" "${import_public_tmp-}" "${import_hex_tmp-}"
  return "$status"
}

# Bootstrap or recover the master identity from its BIP-85 32-byte hex.
agenix_import() {

  identity_rotation_guard

  # Confirm derivation path
  local path="Derive Seeds (BIP-85) > 32-bytes hex > Index Number ${derivation_index-}"
  gum confirm "$path"
  gum_head "$path"

  # Master key (32-byte hex)
  local hex=""

  # If GUI detected, offer QR scanning
  if [[ -n ${DISPLAY-} || -n ${WAYLAND_DISPLAY-} ]]; then
    if [[ "$(gum choose "Scan QR code" "Enter manually")" == "Scan QR code" ]]; then
      hex="$(qr || true)"
    fi
  fi

  # If hex not entered via QR, allow manual input
  if [[ -z $hex ]]; then
    hex="$(gum input --placeholder "Enter 32-byte hex" | xargs)"
  fi

  # Ensure valid 32-byte hex code receieved
  if [[ $hex =~ ^[0-9a-fA-F]{64}$ ]]; then
    gum_info "32-byte hex code validated"
  else
    gum_exit "Failed to receive valid hex code"
  fi
  hex="${hex,,}"

  mkdir -p "$runtime_dir"
  umask 077
  import_work_dir="$(mktemp -d "$runtime_dir/agenix-import.XXXXXX")"
  import_identity_tmp="$(mktemp "$secrets_dir/.id_age.age.XXXXXX")"
  import_public_tmp="$(mktemp "$secrets_dir/.id_age.pub.XXXXXX")"
  import_hex_tmp="$(mktemp "$secrets_dir/.hex.age.XXXXXX")"
  import_committing="false"
  import_committed="false"
  trap 'agenix_import_cleanup "$?"' EXIT
  trap 'exit 130' HUP INT TERM

  local candidate_identity="$import_work_dir/id_age"
  derive age <<<"$hex" >"$candidate_identity"

  local candidate_public
  candidate_public="$(derive public <"$candidate_identity" | xargs)"
  [[ -n $candidate_public ]] || gum_exit "Failed to validate derived age identity"

  # Existing repositories may only recover the same master recipient. Root
  # rotation needs a coordinated fleet workflow and is deliberately separate.
  if [[ -s $secrets_dir/id_age.pub ]]; then
    local current_public
    current_public="$(xargs <"$secrets_dir/id_age.pub")"
    [[ $candidate_public == "$current_public" ]] ||
      gum_exit "Refusing to replace the existing master identity; use the rotation workflow"
  fi

  if [[ -e $secrets_dir/id_age.age || -e $secrets_dir/id_age.pub || -e $secrets_dir/hex.age ]]; then
    gum confirm "Existing master artifacts found. Recover with the same identity?"
  fi

  # Prepare and validate every artifact before replacing any existing file.
  age -e -p <"$candidate_identity" >"$import_identity_tmp"
  printf '%s\n' "$candidate_public" >"$import_public_tmp"
  age -e -R "$import_public_tmp" <<<"$hex" >"$import_hex_tmp"

  local recovered_hex
  recovered_hex="$(age -d -i "$candidate_identity" <"$import_hex_tmp")"
  [[ $recovered_hex == "$hex" ]] || gum_exit "Failed to validate encrypted root hex"

  import_had_id_age_age="false"
  import_had_id_age_pub="false"
  import_had_hex_age="false"
  local target existed_var
  for target in id_age.age id_age.pub hex.age; do
    existed_var="import_had_${target//./_}"
    if [[ -e $secrets_dir/$target ]]; then
      printf -v "$existed_var" '%s' "true"
      cp -p "$secrets_dir/$target" "$import_work_dir/$target"
    fi
  done

  import_committing="true"
  mv "$import_identity_tmp" "$secrets_dir/id_age.age"
  mv "$import_public_tmp" "$secrets_dir/id_age.pub"
  mv "$import_hex_tmp" "$secrets_dir/hex.age"

  # Unlock while the generated plaintext identity still exists.
  agenix_unlock <"$candidate_identity"
  import_committed="true"
  agenix_import_cleanup 0

  git add "$secrets_dir/id_age.pub" "$secrets_dir/hex.age" 2>/dev/null || true
  gum_info "Private age identity written:"
  gum_show "./$secrets_dir/id_age.age"
  gum_info "Public age identity written:"
  gum_show "./$secrets_dir/id_age.pub"
  gum_info "Private 32-byte hex written:"
  gum_show "./$secrets_dir/hex.age"
}

# Decrypt secrets/id_age.age to /tmp/id_age using passhrase
agenix_unlock() {

  # If quiet and the decrypted age identity already exists, stop here
  if [[ ${1:-} == "quiet" ]]; then
    [[ -f $identity_file ]] && return 0
  fi

  # Optionally accept an age identity through standard input
  local id
  id="$([ -t 0 ] || cat)"

  # Attempt to decrypt age identity using passphrse
  if [[ -z $id ]]; then
    [[ ! -f $secrets_dir/id_age.age ]] && gum_exit "./$secrets_dir/id_age.age missing"
    id="$(age -d <"$secrets_dir/id_age.age" 2>/dev/null || true)"
    [[ -z $id ]] && gum_exit "Incorrect passphrase"
  fi

  mkdir -p "$runtime_dir"

  # Do not churn the transition identity when the same key is already unlocked.
  if [[ -f $identity_file && $(<"$identity_file") == "$id" ]]; then
    chmod 600 "$identity_file"
    return 0
  fi

  # Shift any existing phrase to backup
  [[ -f $identity_file ]] && mv "$identity_file" "$previous_identity_file"
  touch "$previous_identity_file"

  # Write decrypted age identity to tmp directory
  echo "$id" >"$identity_file"
  chmod 600 "$identity_file" "$previous_identity_file"

  # Notify user unless quiet
  if [[ ${1:-} != "quiet" ]]; then
    gum style \
      --border="rounded" \
      --border-foreground="29" \
      --foreground="82" \
      --padding="0 1" \
      "🔓 Age identity unlocked"
  fi

}

# Delete decrypted /tmp/id_age
agenix_lock() {
  rm -f "$identity_file" "$previous_identity_file"
  gum style \
    --border="rounded" \
    --border-foreground="124" \
    --foreground="196" \
    --padding="0 1" \
    "🔒 Age identity locked"
}

# Output decrypted secrets/hex.age (32-byte hex)
agenix_hex() {
  local mode="${1:-}"
  [[ -z $mode || $mode == "--check" ]] || gum_exit "Unknown hex option: $mode"
  [[ ! -f $secrets_dir/hex.age ]] && gum_exit "./$secrets_dir/hex.age missing"
  agenix_unlock quiet

  local hex
  hex="$(age -d -i "$identity_file" <"$secrets_dir/hex.age")"
  if [[ $mode == "--check" ]]; then
    [[ $hex =~ ^[0-9a-f]{64}$ ]] ||
      gum_exit "Root hex is not canonical lowercase 32-byte hex"
    gum_info "Root hex is canonical lowercase 32-byte hex"
  else
    printf '%s\n' "$hex"
  fi
}

# Check if directory with id_age and id_age.pub are valid match
agenix_verify() {

  local dir="${1:-$(pwd)}"

  local private_id_file="$dir/id_age"
  local public_id_file="$dir/id_age.pub"

  # Ensure private key exists
  [[ -f $private_id_file ]] ||
    gum_exit "[agenix] $private_id_file missing"

  # Ensure public key exists
  [[ -f $public_id_file ]] ||
    gum_exit "[agenix] $public_id_file missing"

  # Extract public id from current file
  local current_public_id
  current_public_id="$(xargs <"$public_id_file")"

  # Derive expected public id from current private id file (should match above)
  local derived_public_id
  derived_public_id="$(derive public <"$private_id_file" | xargs)"

  # Ensure key pair actually matches
  if [[ $current_public_id == "$derived_public_id" ]]; then
    gum_info "[agenix] $private_id_file valid match"
  else
    gum_warn "[agenix] $private_id_file invalid match"
    return 1
  fi

}

main "${@-}"
