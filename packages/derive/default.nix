{ flake, pkgs, perSystem, ... }: let

  inherit (builtins) readFile;
  inherit (pkgs) gnugrep openssh rage ssh-to-age;
  python3 = ( pkgs.python3.withPackages (ps: [ps.cryptography]) );

in perSystem.self.mkScript {

  name = "derive";
  path = [ gnugrep python3 openssh rage ssh-to-age ];
  text = ''
    source ${flake.lib.bash}

    # First arg is format: age|hex|public|ssh
    format=''${1-}

    # Remaining arguments is args
    args="''${@:2}"

    # If standard input is missing, change format to help
    input="$(input)"
    empty "$input" && format=help

    # Convert based on format
    case "$format" in
      age | a)
        ${readFile ./age.sh}
        ;;
      hex | h)
        echo "$input" | python3 ${./hex.py} "$args"
        ;;
      public | p)
        ${readFile ./public.sh}
        ;;
      ssh | s)
        echo "$input" | python3 ${./ssh.py}
        ;;
      help | *)
        echo "Usage: echo 123 | derive FORMAT [ARGS]"
        echo
        echo "  age"
        echo "  hex [SALT]"
        echo "  public [COMMENT]"
        echo "  ssh"
        echo "  help"
        ;;
    esac
    echo
  '';

}
