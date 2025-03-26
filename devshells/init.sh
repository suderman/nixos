source $LIB; cd $PRJ_ROOT

# Ensure key exists and identity unlocked
hasnt secrets/hex.age && error "$(pwd)/secrets/hex.age missing"
hasnt /tmp/id_age && error "Age identity locked"

  # Convert based on format
  case "${1-}" in
    host | h)
      [[ -z "${2-}" ]] && error "Missing hostname"
      host="hosts/${2-}"
      if has $host; then
        hint "Host configuration exists: $(pwd)/$host"
      else
        mkdir -p $host/users
        for user in $(eza -D users); do
          [[ "$user" == "root" ]] || echo "{ ... }: {}" > $host/users/$user.nix
        done
        cfg="$host/configuration.nix"
        echo "{ flake, ... }: {" > $cfg
        echo "  imports = [ flake.nixosModules.common ];" >> $cfg
        echo "  config = { path = ./.; };" >> $cfg
        echo "}" >> $cfg
        git add $host 2>/dev/null || true
        info "Host configuration staged: $(pwd)/$host"
      fi
      ;&
    user | u)
      [[ -z "${2-}" ]] && error "Missing username"
      user="users/${2-}"
      if has $user; then
        hint "User configuration exists: $(pwd)/$user"
      else
        mkdir -p $user
        echo "x" \
          | rage -er $(cat /tmp/id_age | derive public) \
          > $user/password.age
        cfg="$user/default.nix"
        echo "{" > $cfg
        echo "  uid = null;" >> $cfg
        echo "  description = \"User\";" >> $cfg
        echo "}" >> $cfg
        git add $user 2>/dev/null || true
        info "User configuration staged: $(pwd)/$user"
      fi
      ;&
    all | a)
      sshed build
      agenix generate
      git add secrets/generated 2>/dev/null || true
      agenix rekey -a
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
