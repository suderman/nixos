# inspect_args
local dir="/etc/nixos/secrets" ip hostname force filename key

function main {

  # Ensure ssh-keyscan
  has ssh-keyscan || error "ssh-keyscan missing"

  # Set up args
  force="${args[--force]}"
  ip="${args[host]}"
  hostname="${args[name]}"
  [[ -z "$hostname" ]] && hostname="$ip"

  # Modify hostname to ensure 
  # - it doesn't end in .pub
  # - periods replaces with hypens
  # - only alphanumeric with hypens and underscores
  # - no leading/trailing hypens and underscores
  hostname="$(awk '{ 
    gsub(/\.pub$/, "", $0); 
    gsub(/[\. -]+/, "-", $0); 
    gsub(/[^a-zA-Z0-9_-]+/, "", $0); 
    gsub(/^[-_]+|[-_]+$/, "", $0); 
    print tolower($0) 
  }' <<< $hostname)"

  # Attempt to scan public key
  task ssh-keyscan -t ssh-ed25519 $ip 2> /dev/null
  key="$(last | awk '{print $2} {print $3}' | xargs)"
  filename="${dir}/keys/${hostname}.pub"

  show "key=\"$key\""
  if [[ -z "$key" ]]; then
    error "failed to scan key from $ip"
  fi

  # Ask to delete existing key
  if [[ "$force" == "1" ]]; then
    task "rm -f $filename"
  fi

  if [[ -e $filename ]]; then
    if ask "Overwrite existing \"$hostname\" key?"; then
      task "rm -f $filename"
    else
      error "$hostname already exists in keys directory"
    fi
  fi

  # Write key to file
  show "echo \"\$key\" > $filename"
  echo "$key" > $filename
  info "Success: $name written to $filename"

  # Rekey the secrets with the new identity
  nixos rekey

}


main
