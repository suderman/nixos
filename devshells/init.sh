source $LIB; cd $PRJ_ROOT

# Ensure key exists and identity unlocked
hasnt secrets/hex.age && error "$(pwd)/secrets/hex.age missing"
hasnt /tmp/id_age && error "Age identity locked"

  # Convert based on format
  case "${1-}" in
    host | h)
      echo "init host"
      [[ -z "${2-}" ]] && error "Missing hostname"
      host="hosts/${2-}"
      if hasnt $host; then  
        mkdir -p $host/users
        for user in $(eza -D users); do
          [[ "$user" == "root" ]] || echo "{ ... }: {}" > $host/users/$user.nix
        done
        cfg="$host/configuration.nix"
        echo "{ flake, ... }: {" > $cfg
        echo "  imports = [ flake.nixosModules.common ];" >> $cfg
        echo "  config = { path = ./.; };" >> $cfg
        echo "}" >> $cfg
        git add $host
      fi
      ;&
    user | u)
      echo "init user"
      ;&
    all | a)
      echo "init missing"
      sshed build
      ;;
    help | *)
      echo "Usage: init TARGET"
      echo
      echo "  all"
      echo "  host HOSTNAME"
      echo "  user USERNAME"
      echo "  help"
      ;;
  esac
  echo
