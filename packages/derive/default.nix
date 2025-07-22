{
  pkgs,
  perSystem,
  flake,
  ...
}: let
  inherit (builtins) readFile;
  inherit (pkgs) gnugrep openssh openssl age ssh-to-age;
  python3 = pkgs.python3.withPackages (ps: [ps.cryptography]);
in
  perSystem.self.mkScript {
    name = "derive";
    path = [gnugrep openssl openssh python3 age ssh-to-age];
    text =
      # bash
      ''
        source ${flake.lib.bash}

        # If standard input is missing, change format to help
        input="$(input)"
        [[ -z "$input" ]] && format=help

        # Convert based on format: age|hex|public|ssh
        case "''${1-}" in

          age | a)
            ${readFile ./age.sh}
            ;;

          cert | c)
            cakey="$(echo "$input" | $0 key)"
            cacert="$(echo "$cakey" | python3 ${./cert.py})"
            if [[ -z "''${@:2}" ]]; then
              echo "$cacert"
            else
              common_name=''${2-}
              key=$(echo "$input" | $0 key $common_name)
              echo "$key" | python3 ${./cert.py} \
                --name $common_name \
                --cacert <(echo "$cacert") \
                --cakey <(echo "$cakey")
            fi
            ;;

          hex | h)
            salt=''${2-} # optional salt, optional character length (default 64)
            len=''${3:-64} && [[ "$len" =~ ^[0-9]+$ ]] && (( len >= 1 )) || len=""
            if [[ -z "''${@:2}" ]]; then
              echo "$input" | python3 ${./hex.py}
            else
              echo "$input" | python3 ${./hex.py} "$salt" | cut -c 1-$len
            fi
            ;;

          key | k)
            if [[ ! -z "$(echo "$input" | grep "BEGIN PRIVATE KEY")" ]]; then
              echo "$input"
            else
              echo "$input" | $0 hex ''${2-} | python3 ${./key.py}
            fi
            ;;

          public | p)
            comment=''${2-} # optional ssh comment
            ${readFile ./public.sh}
            ;;

          ssh | s)
            passphrase=''${2-} # optional passphrase
            if [[ -z "''${@:2}" ]]; then
              echo "$input" | python3 ${./ssh.py}
            else
              key=$(mktemp) # write key to tmp file so passphrase can be added
              echo "$input" | python3 ${./ssh.py} > $key
              ssh-keygen -p -f $key -P "" -N "$passphrase" > /dev/null 2>&1
              cat $key
              shred -u $key # delete tmp key after sending to stdout
            fi
            ;;

          help | *)
            echo "Usage: echo 123 | derive FORMAT [ARGS]"
            echo
            echo "  age"
            echo "  cert [NAME]"
            echo "  hex [SALT] [LEN]"
            echo "  key [NAME]"
            echo "  public [COMMENT]"
            echo "  ssh [PASSPHRASE]"
            echo "  help"
            ;;
        esac
      '';
  }
