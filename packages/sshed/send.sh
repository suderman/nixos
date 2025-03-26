# Ensure key exists and identity unlocked
hasnt secrets/hex.age && error "./secrets/hex.age missing"
hasnt /tmp/id_age && error "Age identity locked"

# Ensure host is provided
if empty "$host"; then
  info "Hostname of this SSH host key:"
  host="$(ask)"
fi
empty "$host" && error "Missing host name"

# Ensure IP is provided
if empty "$ip"; then
  info "IP address destination to send this SSH host key:"
  ip="$(ask_ip)"
fi
empty "$ip" && error "Missing destination IP address"

# Send ssh key for selected host to provided IP address
cat secrets/hex.age \
  | rage -di /tmp/id_age \
  | derive hex "$host" \
  | derive ssh \
  | nc -N $ip 12345
