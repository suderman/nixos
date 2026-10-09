#! /usr/bin/env bash
set -euo pipefail

# Pretty output
gum_exit() { gum style --foreground=196 "✖ $*" && return 1; }
gum_warn() { gum style --foreground=124 "✖ $*"; }
gum_info() { gum style --foreground=29 "➜ $*"; }
gum_head() { gum style --foreground=99 "$*"; }
gum_show() { gum style --foreground=177 "    $*"; }

# List subdirectories for given directory
dirs() { find "$1" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'; }

# If PRJ_ROOT is set, change to that directory
[[ -n ${PRJ_ROOT-} ]] && cd "$PRJ_ROOT"

# ---------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------
main() {

  local cmd="${1-}"
  shift

  case "$cmd" in
  activate | a)
    nixos_activate "$@"
    ;;
  add)
    nixos_add "$@"
    ;;
  cache | c)
    nixos_cache "$@"
    ;;
  generate | gen | g)
    nixos_generate "$@"
    ;;
  deploy | d)
    nixos_deploy "$@"
    ;;
  repl | r)
    nixos_repl "$@"
    ;;
  rotation | rotate)
    nixos_rotation "$@"
    ;;
  detect | t)
    nixos_detect "$@"
    ;;
  iso | i)
    nixos_iso "$@"
    ;;
  rollback | b)
    nixos_rollback "$@"
    ;;
  sim | s)
    nixos_sim "$@"
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
Usage: nixos [COMMAND]

  deploy            Deploy a NixOS host configuration
  rollback          Rollback this host to a previous generation
  activate          Activate the current system profile on a host
  cache             Build host closures and devshell environments, then push to Attic
    [HOST...]       Push selected hosts, or use --all for all hosts
  repl              Open a nixos-rebuild repl for a host
  rotation          Rotate the fleet root (see docs/seed-rotation.org)
    status          Show the phase and each host's readiness
    prepare INDEX   Stage the next root and identities beside the current ones
    switch          Select the next identities once every host is prepared
    finalize        Promote the next identities once every host booted them
    back            Step back one phase
                    switch and finalize accept --skip HOST for offline hosts
  add               Add a NixOS host or user
  generate          Generate missing files
  detect            Detect system devices to generate configuration   
    disks [FILE]    Generate disk-configuration.nix
    hardware [FILE] Generate hardware-configuration.nix
  iso               Manage NixOS ISO image
    path            Show path to NixOS ISO
    build           Build NixOS ISO
    flash           Flash NixOS ISO to a USB device
  sim               Manage NixOS virtual machine
    up [iso]        Run virtual machine (default disk, optional ISO)
    rebuild [boot]  Rebuild virtual machine (default switch, optional boot)
    ssh [iso]       SSH into virtual machine (default disk, optinal ISO)
  help              Show this help
EOF
}

# ---------------------------------------------------------------------
# IDENTITY ROTATION
# ---------------------------------------------------------------------
rotation_state="secrets/rotation/state.json"
rotation_root="secrets/rotation/next/hex.age"
master_identity="${AGENIX_RUNTIME_DIR:-/tmp}/id_age"

nixos_rotation() {
  local cmd="${1:-status}"
  shift || true

  case "$cmd" in
  status | s)
    nixos_rotation_status
    ;;
  prepare | p)
    [[ $# -eq 1 && $1 =~ ^[0-9]+$ ]] || gum_exit "Usage: nixos rotation prepare INDEX"
    nixos_rotation_prepare "$1"
    ;;
  switch)
    nixos_rotation_switch "$@"
    ;;
  finalize | f)
    nixos_rotation_finalize "$@"
    ;;
  back)
    nixos_rotation_back
    ;;
  *)
    gum_exit "Unknown rotation command: $cmd"
    ;;
  esac
}

nixos_rotation_phase() {
  jq -r .phase "$rotation_state"
}

# Commands that rewrite fleet identities would race an in-progress rotation.
identity_rotation_guard() {
  [[ $(nixos_rotation_phase) == idle ]] ||
    gum_exit "An identity rotation is in progress; see docs/seed-rotation.org"
}

nixos_rotation_status() {
  local phase
  phase="$(nixos_rotation_phase)"
  gum_info "Rotation phase: $phase"
  [[ $phase != idle ]] || return 0
  gum_info "Next derivation index: $(jq -r .nextIndex "$rotation_state")"
  nixos_rotation_check || true
}

# Report whether each host, except those named, is ready for the current phase.
nixos_rotation_check() {
  local expected host actual status=0
  expected="$(nixos_rotation_phase) $(sha256sum "$rotation_root" | cut -d ' ' -f 1)"
  for host in $(dirs hosts | grep -v iso | sort); do
    if [[ " $* " == *" $host "* ]]; then
      gum_warn "$host skipped"
      continue
    fi
    if [[ $host == "$(hostname)" ]]; then
      actual="$(cat /run/identity-rotation/ready 2>/dev/null || true)"
    else
      actual="$(ssh -o ConnectTimeout=10 "$host" cat /run/identity-rotation/ready 2>/dev/null || true)"
    fi
    if [[ $actual == "$expected" ]]; then
      gum_info "$host ready"
    else
      gum_warn "$host not ready"
      status=1
    fi
  done
  return "$status"
}

# Require readiness before leaving the current phase, honouring --skip HOST.
nixos_rotation_require_ready() {
  local command="$1"
  shift
  local -a skip=()
  while (($#)); do
    [[ $1 == --skip && $# -ge 2 ]] || gum_exit "Usage: nixos rotation $command [--skip HOST]..."
    skip+=("$2")
    shift 2
  done
  nixos_rotation_check "${skip[@]}" ||
    gum_exit "Every host must be ready before: nixos rotation $command"
}

# Compute a change in a disposable worktree and stage it as one atomic patch.
nixos_rotation_apply() {
  [[ -z $(git status --porcelain) ]] || gum_exit "Commit or stash changes first"
  local work patch status
  work="$(mktemp -d)"
  patch="$(mktemp)"
  git worktree add --quiet --detach "$work"
  set +e
  (
    set -e
    cd "$work"
    export PRJ_ROOT="$work"
    "$@"
    git add -A
    git diff --cached --binary >"$patch"
  )
  status=$?
  set -e
  git worktree remove --force "$work"
  if ((status == 0)); then
    git apply --index --whitespace=nowarn "$patch"
  fi
  rm -f "$patch"
  return "$status"
}

nixos_rotation_prepare() {
  local index="$1" root confirm=""
  identity_rotation_guard
  gum confirm "Derive Seeds (BIP-85) > 32-bytes hex > Index Number $index (new seed)"

  if [[ -n ${DISPLAY-}${WAYLAND_DISPLAY-} && $(gum choose "Scan QR code" "Enter manually") == "Scan QR code" ]]; then
    root="$(qr || true)"
    confirm="$root"
  fi
  if [[ -z ${root-} ]]; then
    root="$(gum input --password --placeholder "Next 32-byte hex")"
    confirm="$(gum input --password --placeholder "Repeat next 32-byte hex")"
  fi
  [[ $root == "$confirm" ]] || gum_exit "The two entries differ"
  root="$(xargs <<<"${root,,}")"
  [[ $root =~ ^[0-9a-f]{64}$ ]] || gum_exit "Expected 64 hexadecimal characters"
  [[ $(derive age <<<"$root" | derive public) != "$(xargs <secrets/id_age.pub)" ]] ||
    gum_exit "This is the current root"

  agenix unlock quiet
  nixos_rotation_apply nixos_rotation_prepare_tree "$index" "$root"
  gum_info "Prepared. Commit, deploy every host, then run: nixos rotation switch"
}

nixos_rotation_prepare_tree() {
  local index="$1" root="$2"
  mkdir -p "$(dirname "$rotation_root")"
  age -e -R secrets/id_age.pub -o "$rotation_root" <<<"$root"
  nixos_write_identities "$root" "$index" .next
  jq -n --argjson index "$index" '{phase: "prepare", nextIndex: $index}' >"$rotation_state"
  git add -A
  agenix rekey -a
}

nixos_rotation_switch() {
  [[ $(nixos_rotation_phase) == prepare ]] || gum_exit "Run nixos rotation prepare first"
  nixos_rotation_require_ready switch "$@"
  agenix unlock quiet
  nixos_rotation_apply nixos_rotation_set_phase switch
  gum_info "Switched. Commit, deploy every host with boot and reboot it, then run: nixos rotation finalize"
}

nixos_rotation_back() {
  agenix unlock quiet
  case "$(nixos_rotation_phase)" in
  switch)
    nixos_rotation_apply nixos_rotation_set_phase prepare
    ;;
  prepare)
    nixos_rotation_apply nixos_rotation_cancel_tree
    ;;
  *)
    gum_exit "No rotation in progress"
    ;;
  esac
  gum_info "Stepped back to $(nixos_rotation_phase). Commit and deploy every host."
}

nixos_rotation_set_phase() {
  jq --arg phase "$1" '.phase = $phase' "$rotation_state" >"$rotation_state.new"
  mv "$rotation_state.new" "$rotation_state"
  git add -A
  agenix rekey -a
}

nixos_rotation_cancel_tree() {
  rm -r "$(dirname "$rotation_root")"
  rm -f hosts/*/ssh_host_ed25519_key.pub.next users/*/id_*.pub.next
  jq -n '{phase: "idle"}' >"$rotation_state"
  git add -A
  agenix rekey -a
}

nixos_rotation_finalize() {
  [[ $(nixos_rotation_phase) == switch ]] || gum_exit "Run nixos rotation switch first"
  nixos_rotation_require_ready finalize "$@"
  agenix unlock quiet

  local master encrypted
  umask 077
  master="$(mktemp)"
  encrypted="$(mktemp)"
  # shellcheck disable=SC2064 # remove these exact files even after the function returns
  trap "rm -f -- '$master' '$encrypted'" EXIT
  age -d -i "$master_identity" "$rotation_root" | derive age >"$master"
  gum_info "Choose a passphrase for the new master identity"
  age -e -p -o "$encrypted" "$master"

  nixos_rotation_apply nixos_rotation_finalize_tree "$master"

  # Keep the previous master until every host runs the final generation.
  mv secrets/id_age.age secrets/id_age.age.previous
  mv "$encrypted" secrets/id_age.age
  agenix lock >/dev/null
  agenix unlock <"$master"
  gum_info "Finalized. Commit and deploy every host, then delete secrets/id_age.age.previous"
}

nixos_rotation_finalize_tree() {
  local master="$1" index root public source next
  index="$(jq -r .nextIndex "$rotation_state")"
  root="$(age -d -i "$master_identity" "$rotation_root")"
  public="$(derive public <"$master")"

  # Re-encrypt every source secret from the current master to the new one.
  for source in $(git ls-files '*.age' | grep -Ev '^secrets/(nixos|home|rotation)/|^secrets/hex\.age$'); do
    age -d -i "$master_identity" "$source" | age -e -r "$public" -o "$source.new"
    age -d -i "$master" "$source.new" >/dev/null
    mv "$source.new" "$source"
  done
  age -e -r "$public" -o secrets/hex.age <<<"$root"
  printf '%s\n' "$public" >secrets/id_age.pub

  # Derive canonical identities from the root and confirm prepare staged the same ones.
  nixos_write_identities "$root" "$index"
  for next in hosts/*/ssh_host_ed25519_key.pub.next users/*/id_*.pub.next; do
    cmp -s "$next" "${next%.next}" || gum_exit "${next%.next} does not match its prepared identity"
    rm "$next"
  done

  [[ $(grep -c 'derivationIndex = [0-9]*;' flake.nix) -eq 1 ]] || gum_exit "derivationIndex not found in flake.nix"
  sed -i "s/derivationIndex = [0-9]*;/derivationIndex = $index;/" flake.nix
  rm -r "$(dirname "$rotation_root")"
  jq -n '{phase: "idle"}' >"$rotation_state"
  git add -A

  # Rekey with the new master in the previous-identity slot.
  cp "$master" "${master_identity}_"
  agenix rekey -a
}

# ---------------------------------------------------------------------
# ACTIVATE
# ---------------------------------------------------------------------
nixos_activate() {

  host=$(dirs hosts | grep -v iso | gum choose --header "Choose host:" --selected "$(hostname)")
  operation=$(gum choose --header "Choose operation:" switch boot test dry-activate check)

  if [[ $host == "$(hostname)" ]]; then
    gum_show "sudo /run/current-system/bin/switch-to-configuration $operation"
    sudo /run/current-system/bin/switch-to-configuration "$operation"
  else
    gum_show "ssh $host 'sudo /run/current-system/bin/switch-to-configuration $operation'"
    ssh "$host" "sudo /run/current-system/bin/switch-to-configuration $operation"
  fi

}

# ---------------------------------------------------------------------
# CACHE
# ---------------------------------------------------------------------
nixos_cache() {
  local first_arg="${1-}"
  if [[ $first_arg == "help" ]]; then
    shift || true
    set -- --help "$@"
  elif [[ $first_arg == "push" || $first_arg == "p" || $first_arg == "dry-run" || $first_arg == "dryrun" || $first_arg == "d" ]]; then
    gum_exit "nixos cache no longer uses subcommands; use 'nixos cache [--dry-run] [options] [HOST...]'"
  fi

  local cache="main"
  local dry_run=0
  local select_all=0
  local include_iso=0
  local host system out_path
  local -a requested_hosts=()
  local -a all_hosts=()
  local -a systems=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --cache)
      [[ $# -ge 2 ]] || gum_exit "Missing value for --cache"
      cache="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --all)
      select_all=1
      shift
      ;;
    --include-iso)
      include_iso=1
      shift
      ;;
    -h | --help)
      cat <<EOF
Usage: nixos cache [options] [HOST...]

Build and push host closures plus devshell environments once per host architecture.

Options:
  --cache <name>   Attic cache name to push to (default: main)
  --all            Select all hosts without prompting
  --dry-run        Print host output paths and devshell targets without building or pushing
  --include-iso    Include the iso configuration when auto-selecting hosts
  -h, --help       Show this help
EOF
      return 0
      ;;
    --)
      shift
      requested_hosts+=("$@")
      break
      ;;
    -*)
      gum_exit "Unknown option: $1"
      ;;
    *)
      requested_hosts+=("$1")
      shift
      ;;
    esac
  done

  local host_list
  host_list="$(
    nix eval --raw '.#nixosConfigurations' \
      --apply 'attrs: builtins.concatStringsSep "\n" (builtins.attrNames attrs)'
  )" || gum_exit "Failed to list nixosConfigurations"
  mapfile -t all_hosts <<<"$host_list"

  if [[ ${#requested_hosts[@]} -eq 0 && $select_all -eq 1 ]]; then
    for host in "${all_hosts[@]}"; do
      if [[ $host == "iso" && $include_iso -eq 0 ]]; then
        continue
      fi
      requested_hosts+=("$host")
    done
  fi

  if [[ ${#requested_hosts[@]} -eq 0 ]]; then
    local -a selectable_hosts=()
    local selection
    for host in "${all_hosts[@]}"; do
      if [[ $host == "iso" && $include_iso -eq 0 ]]; then
        continue
      fi
      selectable_hosts+=("$host")
    done

    selection="$(gum choose --no-limit --header='Push which host caches? (ctrl-a to select all)' "${selectable_hosts[@]}")"
    mapfile -t requested_hosts <<<"$selection"
  fi

  for host in "${requested_hosts[@]}"; do
    if [[ ! " ${all_hosts[*]} " =~ [[:space:]]${host}[[:space:]] ]]; then
      gum_exit "Unknown nixosConfiguration host: $host"
    fi
    system="$(nix eval --raw ".#nixosConfigurations.${host}.config.nixpkgs.hostPlatform.system")" || gum_exit "Failed to determine architecture for $host"
    if [[ ! " ${systems[*]} " =~ [[:space:]]${system}[[:space:]] ]]; then
      systems+=("$system")
    fi
  done

  gum_head "Build host closures and devshell environments, then push to Attic:"
  gum_show "cache: $cache"
  for host in "${requested_hosts[@]}"; do
    gum_show "host: $host"
  done

  if [[ $dry_run -eq 0 ]]; then
    attic cache info "$cache" >/dev/null
  fi

  for host in "${requested_hosts[@]}"; do
    if [[ $dry_run -eq 1 ]]; then
      out_path="$(nix eval --raw ".#nixosConfigurations.${host}.config.system.build.toplevel.outPath")"
      gum_show "[dry-run] $host -> $out_path"
      continue
    fi

    gum_info "Building $host..."
    out_path="$(nix build --print-out-paths --no-link ".#nixosConfigurations.${host}.config.system.build.toplevel")"
    gum_show "$out_path"

    gum_info "Pushing $host to Attic cache $cache..."
    attic push "$cache" "$out_path"
  done

  for system in "${systems[@]}"; do
    if [[ $dry_run -eq 1 ]]; then
      gum_show "[dry-run] devshell $system -> .#devShells.${system}.default (nix print-dev-env)"
      continue
    fi

    # nix-direnv uses print-dev-env, whose environment output differs from nix build.
    (
      local tmp
      tmp="$(mktemp -d)"
      trap 'rm -rf "$tmp"' EXIT
      gum_info "Preparing devshell environment for $system..."
      nix print-dev-env --profile "$tmp/devshell" ".#devShells.${system}.default" >/dev/null
      out_path="$(readlink -f "$tmp/devshell")"
      gum_show "$out_path"
      gum_info "Pushing devshell $system to Attic cache $cache..."
      attic push "$cache" "$out_path"
    )
  done
}

# ---------------------------------------------------------------------
# ADD
# ---------------------------------------------------------------------
nixos_add() {
  identity_rotation_guard

  local add_type="${1-}"
  if [[ $add_type != "user" && $add_type != "host" ]]; then
    add_type=$(gum choose --header="Add to this flake:" "user" "host")
  fi
  "nixos_add_${add_type}"
}

nixos_add_user() {

  # Ensure access to age identity
  agenix unlock quiet

  gum_head "Add a user to this flake:"
  local username
  username="$(gum input --placeholder "username")"

  # Ensure a username was provided
  [[ -z $username ]] && gum_exit "Missing username"
  local user="users/${username}"

  # Ensure it doesn't already exist
  if [[ -e $user ]]; then
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
    alejandra -q <"${templates-}"/user.nix >"$user/default.nix"

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
  [[ -z $hostname ]] && gum_exit "Missing hostname"
  local host="hosts/${hostname}"

  # Ensure it doesn't already exist
  if [[ -e $host ]]; then
    gum_info "Host configuration exists:"
    gum_show "./$host"
  else

    # Create host directory
    mkdir -p "$host"/users

    # Add users for home-manager configuration
    for user in $(dirs users); do
      local expr="({ isSystemUser = false; } // (import ./users/$user)).isSystemUser"
      if [[ "$(nix eval --impure --expr "$expr")" == "false" ]]; then
        alejandra -q <"${templates-}"/home.nix >"$host/users/$user.nix"
      fi
    done

    # Create a basic configuration files in this directory
    alejandra -q <"${templates-}"/configuration.nix >"$host/configuration.nix"
    alejandra -q <"${templates-}"/hardware-configuration.nix >"$host/hardware-configuration.nix"
    alejandra -q <"${templates-}"/disk-configuration.nix >"$host/disk-configuration.nix"

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
# Write public identities for every host and user derived from a fleet root.
nixos_write_identities() {
  local root="$1" path="bip85-hex32-index$2" suffix="${3-}" host user
  for host in $(dirs hosts | grep -v iso); do
    derive hex "$host" <<<"$root" | derive ssh | derive public "$host@$path" \
      >"hosts/$host/ssh_host_ed25519_key.pub$suffix"
    gum_show "./hosts/$host/ssh_host_ed25519_key.pub$suffix"
  done
  for user in $(dirs users); do
    derive hex "$user" <<<"$root" | derive ssh | derive public "$user@$path" \
      >"users/$user/id_ed25519.pub$suffix"
    derive hex "$user" <<<"$root" | derive age | derive public \
      >"users/$user/id_age.pub$suffix"
    gum_show "./users/$user/id_ed25519.pub$suffix"
    gum_show "./users/$user/id_age.pub$suffix"
  done
}

nixos_generate() {

  identity_rotation_guard

  # Ensure access to age identity
  agenix unlock quiet

  # Never rewrite fleet identities from a non-canonical root representation.
  agenix hex --check

  # Generate SSH keys and age identities for hosts and users
  gum_info "Generating identities..."
  nixos_write_identities "$(agenix hex)" "$derivation_index"
  git add hosts/*/ssh_host_ed25519_key.pub users/*/id_ed25519.pub users/*/id_age.pub 2>/dev/null || true

  # Ensure Certificate Authority exists
  if [[ -s zones/ca.crt && -s zones/ca.age ]]; then
    gum_info "Certificate Authority exists..."
    gum_show "./zones/ca.crt"
    gum_show "./zones/ca.age"

  # If it doesn't, generate and add to git
  else
    gum_info "Generating Certificate Authority..."

    # Generate CA key and explicit OpenSSL config. We do not rely on the
    # ambient OpenSSL config here because strict TLS clients require the CA
    # certificate itself to declare certificate-signing usage explicitly.
    ca_key=$(mktemp)
    openssl genrsa -out "$ca_key" 4096

    ca_config=$(mktemp)
    cat >"$ca_config" <<'EOF'
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[ req_distinguished_name ]
CN = Suderman CA

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, keyCertSign, cRLSign
EOF

    # Generate CA certificate expiring in 70 years
    openssl req -new -x509 -nodes \
      -config "$ca_config" \
      -extensions v3_ca \
      -days 25568 \
      -key "$ca_key" \
      -out zones/ca.crt

    git add zones/ca.crt 2>/dev/null || true
    gum_show "./zones/ca.crt"

    # Encrypt CA key with age identity
    age -e -r "$(derive public </tmp/id_age)" <"$ca_key" \
      >zones/ca.age
    rm -f "$ca_config"
    shred -u "$ca_key"

    git add zones/ca.age 2>/dev/null || true
    gum_show "./zones/ca.age"

  fi

  # Ensure secrets are rekeyed for all hosts
  gum_info "Rekeying secrets..."
  agenix rekey -a
}

# ---------------------------------------------------------------------
# DEPLOY
# ---------------------------------------------------------------------
nixos_deploy() {

  host=$(dirs hosts | grep -v iso | gum choose --header "Choose host:" --selected "$(hostname)")
  operation=$(gum choose --header "Choose operation:" switch boot test build)
  if [[ $host == "$(hostname)" ]]; then
    gum_show "sudo nixos-rebuild --flake .#$host $operation"
    sudo nixos-rebuild --flake .#"$host" "$operation"
  else
    gum_show "nixos-rebuild --target-host $host --sudo --ask-sudo-password --flake .#$host $operation"
    nixos-rebuild --target-host "$host" --sudo --ask-sudo-password --flake .#"$host" "$operation"
  fi

}

# ---------------------------------------------------------------------
# REPL
# ---------------------------------------------------------------------
nixos_repl() {

  host=$(dirs hosts | grep -v iso | gum choose --header "Choose host:" --selected "$(hostname)")
  gum_show "nixos-rebuild --flake .#$host repl"
  nixos-rebuild --flake .#"$host" repl

}

# ---------------------------------------------------------------------
# DETECT
# ---------------------------------------------------------------------
nixos_detect() {

  case "${1:-help}" in
  disks | d)
    nixos_detect_disks "${2:-}"
    ;;
  hardware | h)
    nixos_detect_hardware "${2:-}"
    ;;
  help | *)
    nixos_help
    ;;
  esac

}

# ---------------------------------------------------------------------
# DETECT DISKS
# ---------------------------------------------------------------------
nixos_detect_disks() {
  local file="${1-}"
  local out
  out="$(lsblk -o ID-LINK,NAME,FSTYPE,LABEL,SIZE,FSUSE%,MOUNTPOINTS --tree=ID-LINK |
    sed 's/^/# /' | cat - "${templates-}"/disk-configuration.nix | alejandra -q)"
  [[ -n $file ]] && echo "$out" >"$file"
  bat --file-name "disk-configuration.nix" <<<"$out"
  nc -N x0.at 9999 <<<"$out" || true
}

# ---------------------------------------------------------------------
# DETECT HARDWARE
# ---------------------------------------------------------------------
nixos_detect_hardware() {
  local file="${1-}"
  local out
  out="$(sudo nixos-generate-config --no-filesystems --show-hardware-config 2>/dev/null |
    alejandra -q)"
  [[ -n $file ]] && echo "$out" >"$file"
  bat --file-name "hardware-configuration.nix" <<<"$out"
  nc -N x0.at 9999 <<<"$out" || true
}

# ---------------------------------------------------------------------
# ISO
# ---------------------------------------------------------------------
nixos_iso() {

  case "${1:-help}" in
  path | p)
    nixos_iso_path
    ;;
  build | b)
    nixos_iso_build
    ;;
  flash | f)
    nixos_iso_flash
    ;;
  help | *)
    nixos_help
    ;;
  esac

}

# ---------------------------------------------------------------------
# ISO PATH
# ---------------------------------------------------------------------
nixos_iso_path() {
  shopt -s nullglob
  local files=(result/iso/nixos*.iso)
  shopt -u nullglob
  if [[ ${#files[@]} -gt 0 ]]; then
    readlink -f "${files[0]}"
  else
    echo ""
  fi
}

# ---------------------------------------------------------------------
# ISO BUILD
# ---------------------------------------------------------------------
nixos_iso_build() {
  gum_show "nix build .#nixosConfigurations.iso.config.system.build.isoImage"
  nix build .#nixosConfigurations.iso.config.system.build.isoImage
}

# ---------------------------------------------------------------------
# ISO FLASH
# ---------------------------------------------------------------------
nixos_iso_flash() {
  local usb_devices usb_selection device
  usb_devices=$(lsblk -dpno NAME,SIZE,MODEL,TRAN | grep -i usb || true)

  # Ensure a USB drive is plugged in
  [[ -z $usb_devices ]] && gum_exit "No USB drives detected."

  # Select USB device
  usb_selection=$(echo "$usb_devices" | gum choose --header "Select USB drive to flash the ISO to")
  device="$(awk '{print $1}' <<<"$usb_selection")"

  # Get path to ISO
  local iso_path
  iso_path="$(nixos_iso_path)"
  if [[ -z $iso_path ]]; then
    nixos_iso_build
    iso_path="$(nixos_iso_path)"
  fi

  # Final confirmation
  gum_info "You are about to write:"
  gum_show "ISO file: $iso_path"
  gum_show "To device: $device"
  echo
  gum confirm "Are you sure? This will erase all data on $device." || exit 1

  # Run dd
  gum_info "Flashing ISO to $device..."
  gum_show "sudo dd if=\"$iso_path\" of=\"$device\" bs=4M status=progress oflag=sync"
  sudo dd if="$iso_path" of="$device" bs=4M status=progress oflag=sync

  gum_info "Done. ISO flashed to $device."
}

# ---------------------------------------------------------------------
# ROLLBACK
# ---------------------------------------------------------------------
nixos_rollback() {

  line="$(sudo nix-env --list-generations -p /nix/var/nix/profiles/system |
    sort -r | gum choose --header "Choose previous generation:")"

  # Do nothing if the selected generation is the current generation
  if [[ $line != *"(current)"* ]]; then
    id=$(echo "$line" | awk '{print $1}') # extract the id

    # Show the commands
    gum_show "sudo nix-env --list-generations -p /nix/var/nix/profiles/system"
    gum_show "sudo nix-env --switch-generation $id -p /nix/var/nix/profiles/system"
    gum_show "sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch"

    # Switch to the selected generation
    sudo nix-env --switch-generation "$id" -p /nix/var/nix/profiles/system
    sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
  fi

}

# ---------------------------------------------------------------------
# SIM
# ---------------------------------------------------------------------
nixos_sim() {

  # Derive ssh private key
  agenix hex |
    derive hex sim |
    derive ssh >hosts/sim/ssh_host_ed25519_key &&
    chmod 600 hosts/sim/ssh_host_ed25519_key

  # Set path to ssh private key in env variable
  export NIX_SSHOPTS="-p 2222 -i hosts/sim/ssh_host_ed25519_key"

  [[ -e hosts/sim/disk1.img ]] || nix run nixpkgs#qemu-img create -f qcow2 hosts/sim/disk1.img 100G
  [[ -e hosts/sim/disk2.img ]] || nix run nixpkgs#qemu-img create -f qcow2 hosts/sim/disk2.img 100G
  [[ -e hosts/sim/disk3.img ]] || nix run nixpkgs#qemu-img create -f qcow2 hosts/sim/disk3.img 100G
  [[ -e hosts/sim/disk4.img ]] || nix run nixpkgs#qemu-img create -f qcow2 hosts/sim/disk4.img 100G

  echo iiiiiii
  case "${1:-help}" in
  up | u)
    nixos_sim_up "${2:-disk}"
    ;;
  rebuild | r)
    nixos_sim_rebuild "${2:-switch}"
    ;;
  ssh | s)
    nixos_sim_ssh "${2:-disk}"
    ;;
  help | *)
    nixos_help
    ;;
  esac

}

# ---------------------------------------------------------------------
# SIM UP
# ---------------------------------------------------------------------
nixos_sim_up() {

  local boot=()
  [[ $1 == "iso" ]] && boot=(-boot d -cdrom "$(nixos iso path)")

  nix run nixpkgs#qemu -- \
    -enable-kvm \
    -m 6144 \
    -cpu host \
    -smp 4 \
    -device virtio-vga-gl \
    -display gtk,gl=on \
    -device ich9-intel-hda,id=snd0 -device hda-output \
    -device virtio-tablet-pci \
    -nic user,hostfwd=tcp::2222-:22,hostfwd=tcp::12345-:12345,hostfwd=tcp::4443-:443 \
    -device virtio-blk-pci,drive=disk1,serial=1 \
    -drive file=hosts/sim/disk1.img,format=qcow2,if=none,id=disk1 \
    -device virtio-blk-pci,drive=disk2,serial=2 \
    -drive file=hosts/sim/disk2.img,format=qcow2,if=none,id=disk2 \
    -device virtio-blk-pci,drive=disk3,serial=3 \
    -drive file=hosts/sim/disk3.img,format=qcow2,if=none,id=disk3 \
    -device virtio-blk-pci,drive=disk4,serial=4 \
    -drive file=hosts/sim/disk4.img,format=qcow2,if=none,id=disk4 \
    "${boot[@]}"

}

# ---------------------------------------------------------------------
# SIM REBUILD
# ---------------------------------------------------------------------
nixos_sim_rebuild() {

  if [[ ${1-switch} == "boot" ]]; then
    gum_show "nixos-rebuild --target-host root@localhost --flake .#sim boot"
    nixos-rebuild --target-host root@localhost --flake .#sim boot
  else
    gum_show "nixos-rebuild --target-host root@localhost --flake .#sim switch"
    nixos-rebuild --target-host root@localhost --flake .#sim switch
  fi

}

# ---------------------------------------------------------------------
# SIM SSH
# ---------------------------------------------------------------------
nixos_sim_ssh() {

  if [[ ${1-disk} == "iso" ]]; then
    gum_show "passh -p x ssh $NIX_SSHOPTS root@localhost"
    # shellcheck disable=SC2086
    passh -p x ssh $NIX_SSHOPTS root@localhost
  else
    gum_show "ssh $NIX_SSHOPTS root@localhost"
    # shellcheck disable=SC2086
    ssh $NIX_SSHOPTS root@localhost
  fi

}

main "${@-}"
