{ flake, pkgs, perSystem, ... }: let

  inherit (builtins) readFile;
  inherit (pkgs) gnugrep openssh rage ssh-to-age;
  python3 = ( pkgs.python3.withPackages (ps: [ps.cryptography]) );

in perSystem.self.mkScript {

  name = "derive";
  path = [ gnugrep python3 openssh rage ssh-to-age ];
  text = ''
    source ${flake.lib.bash}

    # If standard input is missing, change format to help
    input="$(input)"
    [[ -z "$input" ]] && format=help

    # Convert based on format: age|hex|public|ssh
    case "''${1-}" in
      age | a)
        ${readFile ./age.sh}
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
      public | p)
        comment=''${2-} # optional ssh comment
        ${readFile ./public.sh}
        ;;
      ssh | s)
        echo "$input" | python3 ${./ssh.py}
        ;;
      help | *)
        echo "Usage: echo 123 | derive FORMAT [ARGS]"
        echo
        echo "  age"
        echo "  hex [SALT] [LEN]"
        echo "  public [COMMENT]"
        echo "  ssh"
        echo "  help"
        ;;
    esac
    echo
  '';

}
