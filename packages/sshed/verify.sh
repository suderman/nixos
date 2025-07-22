# Determine which key pair to check
if [[ -f ssh_host_ed25519_key ]]; then
  private_key="ssh_host_ed25519_key"
  public_key="ssh_host_ed25519_key.pub"
elif [[ -f id_ed25519 ]]; then
  private_key="id_ed25519"
  public_key="id_ed25519.pub"
else
  error "No valid ed25519 key pair found in $(pwd)"
fi

# Ensure private key exists
[[ -f "$private_key" ]] ||
  error "$(pwd)/$private_key missing"

# Ensure public key exists
[[ -f "$public_key" ]] ||
  error "$(pwd)/$public_key missing"

# Extract type from current public key (should be ssh-ed25519)
current_pub_type="$(cut -d' ' -f1 <"$public_key")"

# Extract key from current public key (without comment)
current_pub_key="$(cut -d' ' -f1,2 <"$public_key")"

# Derive expected public key from current private key (should match above)
derived_pub_key="$(cat "$private_key" | derive public)"

# Ensure public key type
[[ "ssh-ed25519" == "$current_pub_type" ]] ||
  error "$(pwd)/$public_key ssh-ed25519 NOT detected"

# Ensure key pair actually matches
[[ "$current_pub_key" == "$derived_pub_key" ]] ||
  error "$(pwd)/$private_key INVALID, does NOT match existing public key"

info "VALID: SSH host private & public keys match!"
