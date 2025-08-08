#! /usr/bin/env bash
set -euo pipefail

# Pretty output
gum_warn() { gum style --foreground=196 "✖ Error: $*" && exit 1; }
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
  generate | gen | g)
    sshed_generate "$@"
    ;;
  receive | r)
    sshed_receive "$@"
    ;;
  send | s)
    ssshed_send "$@"
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

  generate
  receive
  send [HOST] [IP]
  verify
  help
EOF
}

# ---------------------------------------------------------------------
# GENERATE
# ---------------------------------------------------------------------
sshed_generate() {

  # Ensure key exists and identity unlocked
  [[ ! -f hex.age ]] && gum_warn "./hex.age missing"
  [[ ! -f /tmp/id_age ]] && gum_warn "Age identity locked"

  # Ensure directories exist
  [[ ! -d ./hosts ]] && gum_warn "./hosts directory missing"
  [[ ! -d ./users ]] && gum_warn "./users directory missing"

  # Per each host...
  for host in $(dirs hosts | grep -v iso); do

    # Write the public ssh host key
    age -d -i /tmp/id_age <hex.age |
      derive hex "$host" |
      derive ssh |
      derive public "$host@${derivation_path-}" \
        >"hosts/$host/ssh_host_ed25519_key.pub"
    git add "hosts/$host/ssh_host_ed25519_key.pub" 2>/dev/null || true
    gum_show "./hosts/$host/ssh_host_ed25519_key.pub"

  done

  # Per each user...
  for user in $(dirs users); do

    age -d -i /tmp/id_age <hex.age |
      derive hex "$user" |
      derive ssh |
      derive public "$user@${derivation_path-}" \
        >"users/$user/id_ed25519.pub"
    git add "users/$user/id_ed25519.pub" 2>/dev/null || true
    gum_show "./users/$user/id_ed25519.pub"

  done

}

# ---------------------------------------------------------------------
# RECEIVE
# ---------------------------------------------------------------------
sshed_receive() {

  # Ensure public key exists
  [[ -e ./ssh_host_ed25519_key.pub ]] ||
    gum_warn "$(pwd)/ssh_host_ed25519_key.pub missing"

  # Open port for netcat (if running as root)
  [[ "$(id -u)" == "0" ]] &&
    iptables -A INPUT -p tcp --dport 12345 -j ACCEPT

  # Make and switch to tmp directory to receive key
  dir=$(pwd) tmp=$(pwd)/tmp
  mkdir -p "$tmp"
  cd "$tmp" || gum_warn "Failed to cd into $tmp"

  # Copy existing public key to tmp dir
  cp -f "$dir/ssh_host_ed25519_key.pub" "$tmp/ssh_host_ed25519_key.pub"

  # Demonstrate command to enter on client
  host="$(cut -d' ' -f3 <ssh_host_ed25519_key.pub | cut -d'@' -f1)"
  gum_info "sshed send ${host:-$(hostname)} $(ipaddr lan)"

  # Loop until private key validated
  while true; do

    # Wait for private key to be received over netcat
    nc -l -N 12345 >"$tmp/ssh_host_ed25519_key"

    if $0 verify; then
      mv "$tmp/ssh_host_ed25519_key" "$dir/ssh_host_ed25519_key"
      chmod 600 "$dir/ssh_host_ed25519_key"
      cd "$dir" && rm -rf "$tmp"
      gum_info "VALID ed25519 key received"
      break
    else
      gum_warn "INVALID ed25519 key received"
    fi

    sleep 1

  done

}

# ---------------------------------------------------------------------
# SEND
# ---------------------------------------------------------------------
sshed_send() {

  # Ensure key exists and identity unlocked
  [[ ! -f hex.age ]] && gum_warn "./hex.age missing"
  [[ ! -f /tmp/id_age ]] && gum_warn "Age identity locked"

  # Ensure directories exist
  [[ ! -d ./hosts ]] && gum_warn "./hosts directory missing"

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
  [[ -z "$host" ]] && gum_warn "Missing host name"

  # Ensure IP is provided
  local ip="${2-}"
  if [[ -z "$ip" ]]; then
    gum_head "IP address destination to send this SSH host key:"
    ip="$(input_ip)"
  fi
  [[ -z "$ip" ]] && gum_warn "Missing destination IP address"

  # Send ssh key for selected host to provided IP address
  age -d -i /tmp/id_age <hex.age |
    derive hex "$host" |
    derive ssh |
    nc -N "$ip" 12345

}

# ---------------------------------------------------------------------
# VERIFY
# ---------------------------------------------------------------------
sshed_verify() {

  # Determine which key pair to check
  if [[ -f ssh_host_ed25519_key ]]; then
    private_key="ssh_host_ed25519_key"
    public_key="ssh_host_ed25519_key.pub"
  elif [[ -f id_ed25519 ]]; then
    private_key="id_ed25519"
    public_key="id_ed25519.pub"
  else
    gum_warn "No valid ed25519 key pair found in $(pwd)"
  fi

  # Ensure private key exists
  [[ -f "$private_key" ]] ||
    gum_warn "$(pwd)/$private_key missing"

  # Ensure public key exists
  [[ -f "$public_key" ]] ||
    gum_warn "$(pwd)/$public_key missing"

  # Extract type from current public key (should be ssh-ed25519)
  current_pub_type="$(cut -d' ' -f1 <"$public_key")"

  # Extract key from current public key (without comment)
  current_pub_key="$(cut -d' ' -f1,2 <"$public_key")"

  # Derive expected public key from current private key (should match above)
  derived_pub_key="$(derive public <"$private_key")"

  # Ensure public key type
  [[ "ssh-ed25519" == "$current_pub_type" ]] ||
    gum_warn "$(pwd)/$public_key ssh-ed25519 NOT detected"

  # Ensure key pair actually matches
  [[ "$current_pub_key" == "$derived_pub_key" ]] ||
    gum_warn "$(pwd)/$private_key INVALID, does NOT match existing public key"

  gum_info "VALID: SSH host private & public keys match!"

}

main "${@-}"
