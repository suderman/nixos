{ flake, pkgs, perSystem, ... }: let

  inherit (builtins) readFile;
  inherit (pkgs) bash gnugrep openssh rage ssh-to-age;
  python3 = ( pkgs.python3.withPackages (ps: [ps.cryptography]) );

in perSystem.self.mkScript {

  name = "to";
  path = [ gnugrep python3 openssh rage ssh-to-age ];
  text = ''
    source ${flake.lib.bash}

    # First arg is format: age|hex|public|ssh
    format=''${1-}

    # If standard input is missing, change format to help
    input="$(input)"
    empty "$input" && format=help

    # Convert based on format
    case "$format" in
      age | a)
        ${readFile ./to-age.sh}
        ;;
      hex | h)
        echo "$input" | python3 ${./to-hex.py} "''${@:2}"
        ;;
      public | p)
        ${readFile ./to-public.sh}
        ;;
      ssh | s)
        echo "$input" | python3 ${./to-ssh.py}
        ;;
      help | *)
        echo "Usage: echo 123 | to FORMAT [ARGS]"
        echo
        echo "  age"
        echo "  hex [SALT]"
        echo "  public"
        echo "  ssh"
        echo "  help"
        ;;
    esac
    echo
  '';

}
