# Demonstrate command to enter on client
info "ssh-key send $(ipaddr local)"

# Wait for private key to be received over netcat
nc -l -N 12345 \
  > .ssh_host_ed25519_key

# Derive ssh type from private key
cat .ssh_host_ed25519_key \
  | derive public \
  | cut -d' ' -f1 \
  > .ssh_type

# Write ssh private key if valid
if [[ "ssh-ed25519" == "$(cat .ssh_type)" ]]; then
  mv .ssh_host_ed25519_key ssh_host_ed25519_key
  chmod 600 ssh_host_ed25519_key
  info "Success: valid ed25519 key"
else
  warn "Error: invalid ed25519 key"
fi

# Cleanup
rm -f .ssh_type
