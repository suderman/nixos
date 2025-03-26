# Ensure key exists and identity unlocked
hasnt secrets/hex.age && error "$(pwd)/secrets/hex.age missing"
hasnt /tmp/id_age && error "Age identity locked"

# Ensure directories exist
hasnt ./hosts && error "$(pwd)/hosts directory missing"
hasnt ./users && error "$(pwd)/users directory missing"

# Per each host...
for host in $(eza -D hosts); do

  # Write the public ssh host key
  if has hosts/$host/ssh_host_ed25519_key.pub; then
    hint "Public host key exists: $(pwd)/hosts/$host/ssh_host_ed25519_key.pub"
  else
    cat secrets/hex.age \
      | rage -di /tmp/id_age \
      | derive hex "$host" \
      | derive ssh \
      | derive public "$host@${derivation_path-}" \
      > hosts/$host/ssh_host_ed25519_key.pub
    git add hosts/$host/ssh_host_ed25519_key.pub 2>/dev/null || true
    info "Public host key staged: $(pwd)/hosts/$host/ssh_host_ed25519_key.pub"
  fi

  # Write the (encrypted) secret ssh host key
  if has hosts/$host/ssh_host_ed25519_key.age; then
    hint "Secret host key exists: $(pwd)/hosts/$host/ssh_host_ed25519_key.age"
  else
    cat secrets/hex.age \
      | rage -di /tmp/id_age \
      | derive hex "$host" \
      | derive ssh \
      | rage -er $(cat /tmp/id_age | derive public) \
        -R hosts/$host/ssh_host_ed25519_key.pub \
      > hosts/$host/ssh_host_ed25519_key.age
    git add hosts/$host/ssh_host_ed25519_key.age 2>/dev/null || true
    info "Secret host key staged: $(pwd)/hosts/$host/ssh_host_ed25519_key.age"
  fi

done

# Per each user...
for user in $(eza -D users); do

  # Write the public ssh user key
  if has users/$user/id_ed25519.pub; then
    hint "Public user key exists: $(pwd)/users/$user/id_ed25519.pub"
  else
    cat secrets/hex.age \
      | rage -di /tmp/id_age \
      | derive hex "$user" \
      | derive ssh \
      | derive public "$user@${derivation_path-}" \
      > users/$user/id_ed25519.pub
    git add users/$user/id_ed25519.pub 2>/dev/null || true
    info "Public user key staged: $(pwd)/users/$user/id_ed25519.pub"
  fi

  # Write the (encrypted) secret ssh user key
  if has users/$user/id_ed25519.age; then
    hint "Secret user key exists: $(pwd)/users/$user/id_ed25519.age"
  else
    cat secrets/hex.age \
      | rage -di /tmp/id_age \
      | derive hex "$user" \
      | derive ssh \
      | rage -er $(cat /tmp/id_age | derive public) \
        -R users/$user/id_ed25519.pub \
      > users/$user/id_ed25519.age
    git add users/$user/id_ed25519.age 2>/dev/null || true
    info "Secret user key staged: $(pwd)/users/$user/id_ed25519.age"
  fi

done
