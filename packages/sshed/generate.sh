#! /usr/bin/env bash

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
  show "./users/$user/id_ed25519.pub"

done
