# Ensure public key exists
hasnt ssh_host_ed25519_key.pub && error "Missing ssh host public key"

# Get hostname for displaying send command
host="$(cat ssh_host_ed25519_key.pub | cut -d' ' -f3 | cut -d'@' -f1)"
empty "$host" && host=$(hostname)

function fetch_ssh_key {  

  # Mark that we're waiting to fetch an ssh key
  touch /tmp/fetch_ssh_key

  # Demonstrate command to enter on client
  info "ssh-key send $host $(ipaddr lan)"

  # Wait for private key to be received over netcat
  nc -l -N 12345 > .ssh_host_ed25519_key

  # Derive ssh type from private key
  ssh_type="$(cat .ssh_host_ed25519_key | derive public | cut -d' ' -f1)"

  # Write ssh private key if valid
  if [[ "ssh-ed25519" == "$ssh_type" ]]; then
    mv .ssh_host_ed25519_key ssh_host_ed25519_key
    chmod 600 ssh_host_ed25519_key
    info "Success: valid ed25519 key"
  else
    warn "Error: invalid ed25519 key"
  fi

}

# Loop until private key validated
while true; do

  # Private key missing, wait for new key to be sent
  if hasnt ssh_host_ed25519_key; then
    fetch_ssh_key
  else

    # Existing public key and public key derived from private
    existing_pub="$(cat ssh_host_ed25519_key.pub | cut -d' ' -f1,2)"
    expected_pub="$(cat ssh_host_ed25519_key | derive public)"

    # Validate the existing public key against the expected public key
    if [[ "$existing_pub" == "$expected_pub" ]]; then
      info "VALID ssh host key"
      if [[ "$reboot" == "reboot" ]]; then # reboot upon match
        has /tmp/fetch_ssh_key && reboot now 
      fi
      break

    # If they don't match, refetch the key
    else
      warn "INVALID ssh host key"
      fetch_ssh_key
    fi

  fi

  # Wait a few seconds
  sleep 5

done
