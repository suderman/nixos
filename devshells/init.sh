source $LIB; cd $PRJ_ROOT

# Ensure key exists and identity unlocked
[[ ! -f hex.age ]] && error "./hex.age missing"
[[ ! -f /tmp/id_age ]] && error "Age identity locked"

# host|user|all|help
case "${1-}" in

  # Usage output
  help)
    echo "Usage: init TARGET"
    echo
    echo "  all"
    echo "  host HOSTNAME"
    echo "  user USERNAME"
    echo "  help"
    ;;

  # Generate a host
  host | h)

    # Ensure a hostname was provided
    [[ -z "${2-}" ]] && error "Missing hostname"
    host="hosts/${2-}"

    # Ensure it doesn't already exist
    if has $host; then
      hint "Host configuration exists: ./$host"
    else

      # Create host directory
      mkdir -p $host/users

      # Add users for home-manager configuration
      for user in $(eza -D users); do
        cfg="$host/users/$user.nix"
        if [[ "$user" != "root" ]]; then
          echo "{ flake, ... }: {" > $cfg
          echo "  imports = [ flake.homeModules.common ];" >> $cfg
          echo "}" >> $cfg
        fi
      done

      # Create a basic configuration.nix in this directory
      cfg="$host/configuration.nix"
      echo "{ flake, ... }: {" > $cfg
      echo "  imports = [ flake.nixosModules.common ];" >> $cfg
      echo "  config = { path = ./.; };" >> $cfg
      echo "}" >> $cfg
      
      # Stage in git
      git add $host 2>/dev/null || true
      info "Host configuration staged: ./$host"

    fi
    ;&

  # Generate a user
  user | u)

    # Ensure a username was provided
    [[ -z "${2-}" ]] && error "Missing username"
    user="users/${2-}"

    # Ensure it doesn't already exist
    if has $user; then
      hint "User configuration exists: ./$user"
    else

      # Create host directory
      mkdir -p $user

      # Create an encrypted password.age file (value is x)
      echo "x" \
        | age -er $(cat /tmp/id_age | derive public) \
        > $user/password.age

      # Create a basic default.nix in this directory
      cfg="$user/default.nix"
      echo "{" > $cfg
      echo "  uid = null;" >> $cfg
      echo "  description = \"User\";" >> $cfg
      echo "}" >> $cfg

      # Stage in git
      git add $user 2>/dev/null || true
      info "User configuration staged: ./$user"

    fi
    ;&

  # Generate missing files
  all | *)

    # Generate missing SSH keys for hosts and users
    echo "Generating SSH keys..."
    sshed generate

    # Ensure Certificate Authority exists  
    if [[ -s zones/ca.crt && -s zones/ca.age ]]; then
      echo "Certificate Authority exists..."
      show "./zones/ca.crt"
      show "./zones/ca.age"

    # If it doesn't, generate and add to git
    else
      echo "Generating Certificate Authority..."

      # Generate CA key and save to variable
      ca_key=$(mktemp)
      openssl genrsa -out $ca_key 4096

      # Generate CA certificate expiring in 70 years
      openssl req -new -x509 -nodes \
        -extensions v3_ca \
        -days 25568 \
        -subj "/CN=Suderman CA" \
        -key $ca_key \
        -out zones/ca.crt

      git add zones/ca.crt 2>/dev/null || true
      show "./zones/ca.crt"

      # Encrypt CA key with age identity 
      cat $ca_key | 
        age -er $(cat /tmp/id_age | derive public) \
        > zones/ca.age
      shred -u $ca_key

      git add zones/ca.age 2>/dev/null || true
      show "./zones/ca.age"

    fi

    # Ensure secrets are rekeyed for all hosts
    agenix rekey -a

    ;;

esac
echo
