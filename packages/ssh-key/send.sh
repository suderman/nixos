# Ensure key exists and identity unlocked
hasnt secrets/key.age && error "$(pwd)/secrets/key.age missing"
hasnt /tmp/id_age && error "Age identity locked"

# Ensure IP is provided
empty "$ip" && error "Missing destination IP address"

# Send ssh key for selected host to provided IP address
cat secrets/key.age \
  | rage -di /tmp/id_age \
  | derive hex "$(eza -D hosts | smenu)" \
  | derive ssh \
  | nc -N $ip 12345
