# Ensure key exists and identity unlocked
hasnt secrets/key.age && error "$(pwd)/secrets/key.age missing"
hasnt /tmp/id_age && error "Age identity locked"

# Ensure directories exist
hasnt ./hosts && error "$(pwd)/hosts directory missing"
hasnt ./users && error "$(pwd)/users directory missing"

# Per each host...
for host in $(eza -D hosts); do

  # Write the public ssh host key
  cat secrets/key.age \
    | rage -di /tmp/id_age \
    | derive hex "$host" \
    | derive ssh \
    | derive public "$host@${derivation_path-}" \
    > hosts/$host/ssh_host_ed25519_key.pub
  git add hosts/$host/ssh_host_ed25519_key.pub 2>/dev/null || true
  info "Public host key written: $(pwd)/hosts/$host/ssh_host_ed25519_key.pub"

  # Write the (encrypted) private ssh host key
  cat secrets/key.age \
    | rage -di /tmp/id_age \
    | derive hex "$host" \
    | derive ssh \
    | rage -er $(cat /tmp/id_age | derive public) \
      -R hosts/$host/ssh_host_ed25519_key.pub \
    > hosts/$host/ssh_host_ed25519_key.age
  git add hosts/$host/ssh_host_ed25519_key.age 2>/dev/null || true
  info "Private host key written: $(pwd)/hosts/$host/ssh_host_ed25519_key.age"

done

# Per each user...
for user in $(eza -D users); do

  # Write the public ssh user key
  cat secrets/key.age \
    | rage -di /tmp/id_age \
    | derive hex "$user" \
    | derive ssh \
    | derive public "$user@${derivation_path-}" \
    > users/$user/id_ed25519.pub
  git add users/$user/id_ed25519.pub 2>/dev/null || true
  info "Public user key written: $(pwd)/users/$user/id_ed25519.pub"

  # Write the (encrypted) private ssh user key
  cat secrets/key.age \
    | rage -di /tmp/id_age \
    | derive hex "$user" \
    | derive ssh \
    | rage -er $(cat /tmp/id_age | derive public) \
      -R users/$user/id_ed25519.pub \
      $(printf " -R hosts/%s/ssh_host_ed25519_key.pub" $(eza -D hosts)) \
    > users/$user/id_ed25519.age
  git add users/$user/id_ed25519.age 2>/dev/null || true
  info "Private user key written: $(pwd)/users/$user/id_ed25519.age"

done
