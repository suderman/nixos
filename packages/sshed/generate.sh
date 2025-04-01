# Ensure key exists and identity unlocked
hasnt secrets/hex.age && error "./secrets/hex.age missing"
hasnt /tmp/id_age && error "Age identity locked"

# Ensure directories exist
hasnt ./hosts && error "./hosts directory missing"
hasnt ./users && error "./users directory missing"

# Per each host...
for host in $(eza -D hosts); do

  # Write the public ssh host key
  cat secrets/hex.age \
    | rage -di /tmp/id_age \
    | derive hex "$host" \
    | derive ssh \
    | derive public "$host@${derivation_path-}" \
    > hosts/$host/ssh_host_ed25519_key.pub
  git add hosts/$host/ssh_host_ed25519_key.pub 2>/dev/null || true
  show "./hosts/$host/ssh_host_ed25519_key.pub"

done

# Per each user...
for user in $(eza -D users); do

  cat secrets/hex.age \
    | rage -di /tmp/id_age \
    | derive hex "$user" \
    | derive ssh \
    | derive public "$user@${derivation_path-}" \
    > users/$user/id_ed25519.pub
  git add users/$user/id_ed25519.pub 2>/dev/null || true
  show "./users/$user/id_ed25519.pub"

done
