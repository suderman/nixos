#! /usr/bin/env bash

# Ensure key exists and identity unlocked
[[ ! -f hex.age ]] && gum_warn "./hex.age missing"
[[ ! -f /tmp/id_age ]] && gum_warn "Age identity locked"

# Ensure directories exist
[[ ! -d ./hosts ]] && gum_warn "./hosts directory missing"

# Get IP address and test with ping
input_ip() {
  local ip="" last_ip="" ips="" search=""
  ip="$(gum input --value="192.168.")"
  while :; do
    last_ip="$ip"
    if ping -c1 -w1 "$ip" >/dev/null 2>&1; then
      echo "$ip"
      return 0
    else
      [[ -n "$ip" ]] && search="-s $ip" || search=""
      [[ "$ip" != "$last_ip" ]] && ips="$ip $ips"
      ips="$(echo "${ips} ${ip}" | tr ' ' '\n' | sort | uniq | xargs)"
      # shellcheck disable=SC2086
      ip="$(smenu -m "Retrying IP address" -q -d -a i:3,b c:3,br $search -x 10 <<<"[new] $ips [cancel]")"
      [[ "$ip" == "[cancel]" ]] && return 1
      [[ "$ip" == "[new]" ]] && ip="$(gum input --value="$last_ip")"
    fi
  done
}

# Ensure host is provided
if [[ -z "$host" ]]; then
  # shellcheck disable=SC2046
  host="$(gum choose --header="Hostname of this SSH host key:" $(dirs hosts | grep -v iso))"
fi
[[ -z "$host" ]] && gum_warn "Missing host name"

# Ensure IP is provided
if [[ -z "$ip" ]]; then
  gum_head "IP address destination to send this SSH host key:"
  ip="$(input_ip)"
fi
[[ -z "$ip" ]] && gum_warn "Missing destination IP address"

# Send ssh key for selected host to provided IP address
age -d -i /tmp/id_age <hex.age |
  derive hex "$host" |
  derive ssh |
  nc -N "$ip" 12345
