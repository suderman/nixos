#! /usr/bin/env bash
set -euo pipefail

# Pretty output
gum_warn() { gum style --foreground=196 "✖ Error: $*" && exit 1; }
gum_info() { gum style --foreground=29 "➜ $*"; }
gum_head() { gum style --foreground=99 "$*"; }
gum_show() { gum style --foreground=177 "    $*"; }

# List subdirectories for given directory
dirs() { find "$1" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'; }

# ---------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------
main() {

  local cmd="${1-}"
  shift

  case "$cmd" in
  add | a)
    nixos_add "$@"
    ;;
  generate | gen | g)
    nixos_generate "$@"
    ;;
  help | *)
    nixos_help
    ;;
  esac

}

# ---------------------------------------------------------------------
# HELP
# ---------------------------------------------------------------------
nixos_help() {
  cat <<EOF
Usage: nixos COMMAND

  deploy
  repl
  add
  generate
  help
EOF
}

# ---------------------------------------------------------------------
# ADD
# ---------------------------------------------------------------------
nixos_add() {
  add_type=$(gum choose --header="Add to this flake:" "user" "host")
  "nixos_add_${add_type}"
}

nixos_add_user() {
  gum_head "Add a user to this flake:"
  local username
  username="$(gum input --placeholder "username")"

  # Ensure a username was provided
  [[ -z "$username" ]] && gum_warn "Missing username"
  local user="users/${username}"

  # Ensure it doesn't already exist
  if [[ -e "$user" ]]; then
    gum_info "User configuration exists:"
    gum_show "./$user"
  else

    # Create host directory
    mkdir -p "$user"

    # Create an encrypted password.age file (value is x)
    echo "x" |
      age -e -r "$(derive public </tmp/id_age)" \
        >"$user"/password.age

    # Create a basic default.nix in this directory
    {
      echo '{'
      echo '  uid = null;'
      echo '  description = "User";'
      echo '  openssh.authorizedKeys.keyFiles = [./id_ed25519.pub];'
      echo '}'
    } | alejandra -q >"$user/default.nix"

    # Stage in git
    git add "$user" 2>/dev/null || true
    gum_info "User configuration staged: ./$user"
  fi

  # Generate missing files
  nixos_generate
}

nixos_add_host() {
  gum_head "Add a host to this flake:"
  local hostname
  hostname="$(gum input --placeholder "hostname")"

  # Ensure a hostname was provided
  [[ -z "$hostname" ]] && gum_warn "Missing hostname"
  local host="hosts/${hostname}"

  # Ensure it doesn't already exist
  if [[ -e "$host" ]]; then
    gum_info "Host configuration exists:"
    gum_show "./$host"
  else

    # Create host directory
    mkdir -p "$host"/users

    # Add users for home-manager configuration
    for user in $(dirs users); do
      local expr="({ isSystemUser = false; } // (import ./users/$user)).isSystemUser"
      if [[ "$(nix eval --impure --expr "$expr")" == "false" ]]; then
        {
          echo '{ flake, ... }: {'
          echo '  imports = [ flake.homeModules.common ];'
          echo '}'
        } | alejandra -q >"$host/users/$user.nix"
      fi
    done

    # Create a basic configuration.nix in this directory
    {
      echo '{ flake, ... }: {'
      echo '  imports = [ flake.nixosModules.common ];'
      echo '}'
    } | alejandra -q >"$host/configuration.nix"

    # Stage in git
    git add "$host" 2>/dev/null || true
    gum_info "Host configuration staged: ./$host"
  fi

  # Generate missing files
  nixos_generate
}

# ---------------------------------------------------------------------
# GENERATE
# ---------------------------------------------------------------------
nixos_generate() {

  # Generate missing SSH keys for hosts and users
  gum_info "Generating SSH keys..."
  sshed generate

  # Ensure Certificate Authority exists
  if [[ -s zones/ca.crt && -s zones/ca.age ]]; then
    gum_info "Certificate Authority exists..."
    gum_show "./zones/ca.crt"
    gum_show "./zones/ca.age"

  # If it doesn't, generate and add to git
  else
    gum_info "Generating Certificate Authority..."

    # Generate CA key and save to variable
    ca_key=$(mktemp)
    openssl genrsa -out "$ca_key" 4096

    # Generate CA certificate expiring in 70 years
    openssl req -new -x509 -nodes \
      -extensions v3_ca \
      -days 25568 \
      -subj "/CN=Suderman CA" \
      -key "$ca_key" \
      -out zones/ca.crt

    git add zones/ca.crt 2>/dev/null || true
    gum_show "./zones/ca.crt"

    # Encrypt CA key with age identity
    age -e -r "$(derive public </tmp/id_age)" <"$ca_key" \
      >zones/ca.age
    shred -u "$ca_key"

    git add zones/ca.age 2>/dev/null || true
    gum_show "./zones/ca.age"

  fi

  # Ensure secrets are rekeyed for all hosts
  gum_info "Rekeying secrets..."
  agenix rekey -a
}

main "${@-}"
