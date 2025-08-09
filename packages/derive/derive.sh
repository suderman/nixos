#! /usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------
main() {

  local cmd="${1-}"
  shift

  # If standard input is missing, change cmd to help
  local input
  input="$([ -t 0 ] || cat)"
  [[ -z "$input" ]] && cmd="help"

  case "$cmd" in
  age | a)
    derive_age "$@" <<<"$input"
    ;;
  hex | h)
    derive_hex "$@" <<<"$input"
    ;;
  public | p)
    derive_public "$@" <<<"$input"
    ;;
  ssh | s)
    derive_ssh "$@" <<<"$input"
    ;;
  help | *)
    derive_help
    ;;
  esac

}

# ---------------------------------------------------------------------
# HELP
# ---------------------------------------------------------------------
derive_help() {
  cat <<EOF
Usage: derive FORMAT [ARGS] <<<123

  age
  hex [SALT] [LEN]
  public [COMMENT]
  ssh [PASSPHRASE]
  help
EOF
}

# ---------------------------------------------------------------------
# DERIVE_AGE
# ---------------------------------------------------------------------
derive_age() {

  # Exit if standard input is missing
  local input
  input="$([ -t 0 ] || cat)"
  [[ -z "$input" ]] && exit 0

  # Use derive ssh (this package) to generate ssh key from input
  local ssh
  ssh="$(derive_ssh <<<"$input")"
  [[ -z "$ssh" ]] && exit 0

  # Use https://github.com/Mic92/ssh-to-age to generate age from ssh key
  local age
  age="$(ssh-to-age -private-key <<<"$ssh")"
  [[ -z "$age" ]] && exit 0

  # Use derive public (this package) to generate formatted identity and output
  echo "# imported from: $(derive_public <<<"$ssh")"
  echo "# public key: $(derive_public <<<"$age")"
  echo "$age"

}

# ---------------------------------------------------------------------
# DERIVE_HEX
# ---------------------------------------------------------------------
derive_hex() {

  # Exit if standard input is missing
  local input
  input="$([ -t 0 ] || cat)"
  [[ -z "$input" ]] && exit 0

  local salt="${1-}" # optional salt, optional character length (default 64)
  local len="${2:-64}" && [[ "$len" =~ ^[0-9]+$ ]] && ((len >= 1)) || len=""
  if [[ -z "$salt" ]]; then
    python3 "${path_to_hex_py-}" <<<"$input"
  else
    python3 "${path_to_hex_py-}" "$salt" <<<"$input" | cut -c 1-"$len"
  fi

}

# ---------------------------------------------------------------------
# DERIVE_KEY
# ---------------------------------------------------------------------
derive_key() {

  # Exit if standard input is missing
  local input
  input="$([ -t 0 ] || cat)"
  [[ -z "$input" ]] && exit 0

  if grep -q "BEGIN PRIVATE KEY" <<<"$input"; then
    echo "$input"
  else
    local name="${1-}" # optional key name
    derive_hex "$name" <<<"$input" | python3 "${path_to_key_py-}"
  fi

}

# ---------------------------------------------------------------------
# DERIVE_PUBLIC
# ---------------------------------------------------------------------
derive_public() {

  # Exit if standard input is missing
  local input
  input="$([ -t 0 ] || cat)"
  [[ -z "$input" ]] && exit 0

  # If age identity detected, extract recipient from secret and output
  if grep -q "AGE-SECRET-KEY" <<<"$input"; then
    age-keygen -y <<<"$input"

  # If ssh ed25519 detected, extract public key from secret and output
  elif grep -q "OPENSSH PRIVATE KEY" <<<"$input"; then
    local comment="${1-}" # optional ssh comment
    xargs <<<"$(ssh-keygen -y -f <(echo "$input") | cut -d ' ' -f 1,2) $comment"

  # Fallback on echoing the input to output
  else
    echo "$input"
  fi

}

# ---------------------------------------------------------------------
# DERIVE_SSH
# ---------------------------------------------------------------------
derive_ssh() {

  # Exit if standard input is missing
  local input
  input="$([ -t 0 ] || cat)"
  [[ -z "$input" ]] && exit 0

  local passphrase="${1-}" # optional passphrase
  if [[ -z "$passphrase" ]]; then
    python3 "${path_to_ssh_py-}" <<<"$input"
  else
    local key
    key="$(mktemp)" # write key to tmp file so passphrase can be added
    python3 "${path_to_ssh_py-}" <<<"$input" >"$key"
    ssh-keygen -p -f "$key" -P "" -N "$passphrase" >/dev/null 2>&1
    cat "$key"
    shred -u "$key" # delete tmp key after sending to stdout
  fi

}

main "${@-}"
