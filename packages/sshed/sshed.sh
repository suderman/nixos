#! /usr/bin/env bash
set -euo pipefail

# Pretty output
gum_exit() { gum style --foreground=196 "✖ $*" && return 1; }
gum_warn() { gum style --foreground=124 "✖ $*"; }
gum_info() { gum style --foreground=29 "➜ $*"; }
gum_head() { gum style --foreground=99 "$*"; }
gum_show() { gum style --foreground=177 "    $*"; }

# List subdirectories for given directory
dirs() { find "$1" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'; }

# ---------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------
main() {

  local cmd="${1-}"
  shift

  case "$cmd" in
  import | i)
    sshed_import "$@"
    ;;
  receive | r)
    sshed_receive "$@"
    ;;
  send | s)
    sshed_send "$@"
    ;;
  verify | v)
    sshed_verify "$@"
    ;;
  help | *)
    sshed_help
    ;;
  esac

}

# ---------------------------------------------------------------------
# HELP
# ---------------------------------------------------------------------
sshed_help() {
  cat <<EOF
Usage: sshed COMMAND

  import [DIR]
  receive [DIR]
  send [HOST] [IP]
  verify [DIR]
  help
EOF
}

# ---------------------------------------------------------------------
# IMPORT
# ---------------------------------------------------------------------
sshed_import() {

  local dir="${1:-$(pwd)}"
  local tmp="$dir/tmp"

  # Ensure public key exists
  [[ -e $dir/ssh_host_ed25519_key.pub ]] ||
    gum_exit "$dir/ssh_host_ed25519_key.pub missing"

  # Determine hostname from key
  local hostname
  hostname="$(cut -d' ' -f3 <"$dir/ssh_host_ed25519_key.pub" | cut -d'@' -f1)"

  # Copy existing public key to tmp dir
  mkdir -p "$tmp"
  cp -f "$dir/ssh_host_ed25519_key.pub" "$tmp/ssh_host_ed25519_key.pub"

  # Loop until private key validated
  while true; do

    # Write the public ssh host key
    gum input --placeholder "Enter 32-byte hex" | xargs |
      derive hex "${hostname:-$(hostname)}" |
      derive ssh >"$tmp/ssh_host_ed25519_key"

    if sshed_verify "$tmp"; then
      mv "$tmp/ssh_host_ed25519_key" "$dir/ssh_host_ed25519_key"
      chmod 600 "$dir/ssh_host_ed25519_key"
      rm -rf "$tmp"
      break
    fi

    sleep 1

  done

}

# ---------------------------------------------------------------------
# RECEIVE
# ---------------------------------------------------------------------
sshed_receive() {

  local dir="${1:-$(pwd)}"
  local tmp="$dir/tmp"

  # Ensure public key exists
  [[ -e $dir/ssh_host_ed25519_key.pub ]] ||
    gum_exit "$dir/ssh_host_ed25519_key.pub missing"

  # Open port for netcat (if running as root)
  [[ "$(id -u)" == "0" ]] &&
    iptables -A INPUT -p tcp --dport 12345 -j ACCEPT

  # Determine hostname from key
  local hostname
  hostname="$(cut -d' ' -f3 <"$dir/ssh_host_ed25519_key.pub" | cut -d'@' -f1)"

  # Copy existing public key to tmp dir
  mkdir -p "$tmp"
  cp -f "$dir/ssh_host_ed25519_key.pub" "$tmp/ssh_host_ed25519_key.pub"

  # Demonstrate command to enter on client
  gum_info "sshed send ${hostname:-$(hostname)} $(ipaddr lan)"

  # Loop until private key validated
  while true; do

    # Wait for private key to be received over netcat
    nc -l -N 12345 >"$tmp/ssh_host_ed25519_key"

    if sshed_verify "$tmp"; then
      mv "$tmp/ssh_host_ed25519_key" "$dir/ssh_host_ed25519_key"
      chmod 600 "$dir/ssh_host_ed25519_key"
      rm -rf "$tmp"
      break
    fi

    sleep 1

  done

}

# ---------------------------------------------------------------------
# SEND
# ---------------------------------------------------------------------
sshed_send() {

  # Ensure directories exist
  [[ ! -d ./hosts ]] && gum_exit "./hosts directory missing"

  # Get IP address and test with ping
  input_ip() {
    local ip="" last_ip="" ips="" search=""
    ip="$(gum input --value="192.168.")"
    while :; do
      last_ip="$ip"
      if ping -c1 -w1 "$ip" >/dev/null 2>&1; then
        echo "$ip"
        return 0
      else
        [[ -n "$ip" ]] && search="-s $ip" || search=""
        [[ "$ip" != "$last_ip" ]] && ips="$ip $ips"
        ips="$(echo "${ips} ${ip}" | tr ' ' '\n' | sort | uniq | xargs)"
        # shellcheck disable=SC2086
        ip="$(smenu -m "Retrying IP address" -q -d -a i:3,b c:3,br $search -x 10 <<<"[new] $ips [cancel]")"
        [[ "$ip" == "[cancel]" ]] && return 1
        [[ "$ip" == "[new]" ]] && ip="$(gum input --value="$last_ip")"
      fi
    done
  }

  # Ensure host is provided
  local host="${1-}"
  if [[ -z "$host" ]]; then
    # shellcheck disable=SC2046
    host="$(gum choose --header="Hostname of this SSH host key:" $(dirs hosts | grep -v iso))"
  fi
  [[ -z "$host" ]] && gum_exit "Missing host name"

  # Ensure IP is provided
  local ip="${2-}"
  if [[ -z "$ip" ]]; then
    gum_head "IP address destination to send this SSH host key:"
    ip="$(input_ip)"
  fi
  [[ -z "$ip" ]] && gum_exit "Missing destination IP address"

  # Send ssh key for selected host to provided IP address
  agenix hex |
    derive hex "$host" |
    derive ssh |
    nc -N "$ip" 12345

}

# ---------------------------------------------------------------------
# VERIFY
# ---------------------------------------------------------------------
sshed_verify() {

  local dir="${1:-$(pwd)}"

  # Determine which key pair to check
  if [[ -f "$dir/ssh_host_ed25519_key" ]]; then
    private_key_file="$dir/ssh_host_ed25519_key"
    public_key_file="$dir/ssh_host_ed25519_key.pub"
  elif [[ -f "$dir/id_ed25519" ]]; then
    private_key_file="$dir/id_ed25519"
    public_key_file="$dir/id_ed25519.pub"
  else
    gum_exit "[sshed] no valid ed25519 key pair found in $dir"
  fi

  # Ensure private key exists
  [[ -f "$private_key_file" ]] ||
    gum_exit "[sshed] $private_key_file missing"

  # Ensure public key exists
  [[ -f "$public_key_file" ]] ||
    gum_exit "[sshed] $public_key_file missing"

  # Extract type from current public key (should be ssh-ed25519)
  current_pub_type="$(cut -d' ' -f1 <"$public_key_file" | xargs)"

  # Extract key from current public key (without comment)
  current_pub_key="$(cut -d' ' -f1,2 <"$public_key_file" | xargs)"

  # Derive expected public key from current private key (should match above)
  derived_pub_key="$(derive public <"$private_key_file" | xargs)"

  # Ensure public key type
  if [[ "ssh-ed25519" != "$current_pub_type" ]]; then
    gum_warn "[sshed] $public_key_file ssh-ed25519 NOT detected"
    return 1
  fi

  # Ensure key pair actually matches
  if [[ "$current_pub_key" == "$derived_pub_key" ]]; then
    gum_info "[sshed] $private_key_file valid match"
  else
    gum_warn "[sshed] $private_key_file invalid match"
    return 1
  fi

}

main "${@-}"
