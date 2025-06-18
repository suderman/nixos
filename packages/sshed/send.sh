# Ensure key exists and identity unlocked
[[ ! -f hex.age ]] && error "./hex.age missing"
[[ ! -f /tmp/id_age ]] && error "Age identity locked"

# Ensure host is provided
if [[ -z "$host" ]]; then
  info "Hostname of this SSH host key:"
  host="$(ask)"
fi
[[ -z "$host" ]] && error "Missing host name"

# Ensure IP is provided
if [[ -z "$ip" ]]; then
  info "IP address destination to send this SSH host key:"
  ip="$(ask_ip)"
fi
[[ -z "$ip" ]] && error "Missing destination IP address"

# Send ssh key for selected host to provided IP address
cat hex.age |
  age -di /tmp/id_age |
  derive hex "$host" |
  derive ssh |
  nc -N $ip 12345
