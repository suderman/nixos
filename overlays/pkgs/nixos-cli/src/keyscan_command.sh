include awk:gawk ssh-keyscan:openssh
local dir="/etc/nixos/secrets" ip hostname

function main {

  # Ensure ssh-keyscan
  has ssh-keyscan || error "ssh-keyscan missing"

  # Set up args
  ip="${args[ip]}" hostname="$(hostname)"

  # Attempt to scan public key
  task ssh-keyscan -t ssh-ed25519 $ip 2> /dev/null
  local key="$(last | awk '{print $2} {print $3}' | xargs)"
  local filename="$(filename)"

  # Check for acquired key
  show "key=\"$key\""
  if [[ -z "$key" ]]; then
    error "failed to scan key from $ip"
  fi

  # Add extra key
  if [[ "${args[--add]}" == "1" ]]; then
    filename="$(filename unique)"

  # Replace existing key
  else
    # Delete any existing keys if forced
    if [[ "${args[--force]}" == "1" ]]; then
      remove "$filename"
    # Otherwise, first check if key exists
    else
      if [[ -e "$filename" ]]; then
        # Ask before deleting existing key
        info "Key \"$hostname\" already exists, replace?" 
        if confirm; then
          remove "$filename"
        # Exit with error
        else
          error "Key \"$hostname\" already exists"
        fi
      fi
    fi
  fi

  # Write key to file
  info "Writing $filename"
  show 'echo "${key}" > '"$filename"
  echo "${key}" > $filename

  # Rekey the secrets with the new identity
  if [[ "${args[--commit]}" == "1" ]]; then
    nixos rekey --commit
  else
    nixos rekey
  fi

}

# Modify hostname to ensure 
# - it doesn't end in .pub
# - periods replaces with hypens
# - only alphanumeric with hypens and underscores
# - no leading/trailing hypens and underscores
# - if it starts with a number (IP address), prepend with underscore
function hostname {
  local hostname="${args[hostname]}"
  [[ -z "$hostname" ]] && hostname="${args[ip]}"
  echo "$(awk '{ 
    gsub(/\.pub$/, "", $0); 
    gsub(/[\. -]+/, "-", $0); 
    gsub(/[^a-zA-Z0-9_-]+/, "", $0); 
    gsub(/^[-_]+|[-_]+$/, "", $0); 
    if (substr($0, 1, 1) ~ /^[0-9]/) { $0 = "_" $0 }; 
    print tolower($0) 
  }' <<< $hostname)"
}

function filename {
  local filename="${dir}/keys/${hostname}.pub"
  if [[ "$1" == "unique" ]]; then
    [[ -e $filename ]] && echo "${dir}/keys/${hostname}-$(date +%s).pub"
  else
    echo "$filename"
  fi
}

function remove {
  info "Removing $1"
  task "rm -f $1"
}

main
