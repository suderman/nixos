#! /usr/bin/env bash

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
