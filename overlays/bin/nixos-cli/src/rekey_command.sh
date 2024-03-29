include awk:gawk git sed:gnused
local dir="/etc/nixos/secrets"

function main {

  # Ensure agenix
  has agenix || error "agenix missing"

  # Update keys/default.nix
  write_keys_nix 

  # Rekey secrets with agenix and restage on git
  if [[ "$(prev_hash)" != "$(calc_hash)" ]] || [[ "${args[--force]}" == "1" ]]; then
    agenix_rekey && update_hash && git_commit
  else
    info "No changes detected"
  fi

}

# Write the default.nix file compiling all public keys
function write_keys_nix {

  # Ouput file path 
  local nix="$dir/keys/default.nix"

  # List of all key names
  local users=""
  local systems=""

  info "Writing $nix"

  # Build recursive attribute set
  echo "$(prev_hash)" > $nix
  echo "# Do not modify this file!  It was generated by ‘nixos rekey’ "  >> $nix
  echo "# and may be overwritten by future invocations. "                >> $nix
  echo "# Please add public keys to $dir/keys/*.pub "                    >> $nix
  echo "rec {"                                                           >> $nix
  echo ""                                                                >> $nix

  # Read each @*.pub file (users) in the directory
  for file in $dir/keys/@*.pub; do

    # Derive the attribute key from the filename
    local key=$(basename "$file" ".pub")
    key="${key#@}" # remove @ from start

    # Write the attribute key and value to default.nix
    echo "  users.$key = \"$(cat "$file")\";" >> $nix

    # Collect list of key names
    users=$(echo " $users users.$key " | xargs)

  done

  # Finish with users, containing list of key names
  echo "  users.all = [ $users ];" >> $nix

  echo "" >> $nix

  # Read each *.pub file in the directory
  for file in $dir/keys/*.pub; do 
    [[ "$file" =~ ^$dir/keys/@.* ]] && continue

    # Derive the attribute key from the filename
    local key=$(basename "$file" ".pub")

    # Write the attribute key and value to default.nix
    echo "  systems.$key = \"$(cat "$file")\";" >> $nix

    # Collect list of key names
    systems=$(echo " $systems systems.$key " | xargs)

  done

  # Finish with systems, containing list of key names
  echo "  systems.all = [ $systems ];" >> $nix

  echo "" >> $nix

  # Finish with all, containing list of key names
  echo "  all = users.all ++ systems.all;" >> $nix

  echo ""  >> $nix
  echo "}" >> $nix

  show "echo \"rec { ... }\" > $nix"

}

function prev_hash {
  head -n1 $dir/keys/default.nix
}

function calc_hash {
  echo "# $(ls -lah $dir/keys/*.pub | md5sum | awk '{print $1}')"
}

function update_hash {
  local file="$dir/keys/default.nix"
  local hash="$(calc_hash)"
  sed -i "1s/.*/$hash/" $file
}

# Rekey secrets with agenix
function agenix_rekey {

  # Rekey and add any new secrets
  info "Rekeying secrets with agenix"

  show "cd $dir/secrets && agenix --rekey"
  cd $dir && agenix --rekey && return 0
  return 1

}

function git_commit {
  info "Adding files to the staging area"
  task "cd $dir"\
       '&& git add ./keys ./files/*.age'
  if [[ "${args[--commit]}" == "1" ]]; then
    info "Committing staged files to the repository"
    task "cd $dir"\
         '&& git commit ./keys ./files/*.age -m rekey'
  fi
}

main
