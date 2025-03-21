# Ensure private key exists
has ssh_host_ed25519_key \
  || error "$(pwd)/ssh_host_ed25519_key missing"

# Ensure public key exists
has ssh_host_ed25519_key.pub \
  || error "$(pwd)/ssh_host_ed25519_key.pub missing"

# Extract type from current public key (should be ssh-ed25519)
current_pub_type="$(cat ssh_host_ed25519_key.pub | cut -d' ' -f1)"

# Extract key from current public key (without comment)
current_pub_key="$(cat ssh_host_ed25519_key.pub | cut -d' ' -f1,2)"

# Derive expected public key from current private key (should match above)
derived_pub_key="$(cat ssh_host_ed25519_key | derive public)"

# Ensure public key type
[[ "ssh-ed25519" == "$current_pub_type" ]] \
  || error "$(pwd)/ssh_host_ed25519_key.pub ssh-ed25519 NOT detected"

[[ "$current_pub_key" == "$derived_pub_key" ]] \
  || error "$(pwd)/ssh_host_ed25519_key INVALID, does NOT match existing public key"

info "VALID: SSH host private & public keys match!"
