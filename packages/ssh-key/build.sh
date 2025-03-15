# Ensure key exists and identity unlocked
hasnt secrets/key.age && error "$(pwd)/secrets/key.age missing"
hasnt /tmp/id_age && error "Age identity locked"

# Ensure directories exist
hasnt hosts && error "$(pwd)/hosts directory missing"
hasnt users && error "$(pwd)/users directory missing"

# Derivation path for key
path="bip85-hex32-index1"

# Per each host...
for host in $(ls hosts); do

  # Write the public ssh host key
  cat secrets/key.age \
    | rage -di /tmp/id_age \
    | derive hex "$host" \
    | derive ssh \
    | derive public "$host@${derivationPath-}" \
    > hosts/$host/ssh_host_ed25519_key.pub
  git add hosts/$host/ssh_host_ed25519_key.pub
  info "Public host key written: $(pwd)/hosts/$host/ssh_host_ed25519_key.pub"

  # Write the (encrypted) private ssh host key
  cat secrets/key.age \
    | rage -di /tmp/id_age \
    | derive hex "$host" \
    | derive ssh \
    | rage -er $(cat /tmp/id_age | derive public) \
      -R hosts/$host/ssh_host_ed25519_key.pub \
    > hosts/$host/ssh_host_ed25519_key.age
  git add hosts/$host/ssh_host_ed25519_key.age
  info "Private host key written: $(pwd)/hosts/$host/ssh_host_ed25519_key.age"

done

# Per each user...
for user in $(ls users); do

  # Write the public ssh user key
  cat secrets/key.age \
    | rage -di /tmp/id_age \
    | derive hex "$user" \
    | derive ssh \
    | derive public "$user@${derivationPath-}" \
    > users/$user/id_ed25519.pub
  git add users/$user/id_ed25519.pub
  info "Public user key written: $(pwd)/users/$user/id_ed25519.pub"

  # Write the (encrypted) private ssh user key
  cat secrets/key.age \
    | rage -di /tmp/id_age \
    | derive hex "$user" \
    | derive ssh \
    | rage -er $(cat /tmp/id_age | derive public) \
      -R users/$user/id_ed25519.pub \
      $(printf " -R hosts/%s/ssh_host_ed25519_key.pub" $(ls hosts)) \
    > users/$user/id_ed25519.age
  git add users/$user/id_ed25519.age
  info "Private user key written: $(pwd)/users/$user/id_ed25519.age"

done
