{ flake, pkgs, perSystem, ... }: let

  inherit (builtins) readFile;
  inherit (pkgs) bash gnugrep openssh rage ssh-to-age;
  python3 = ( pkgs.python3.withPackages (ps: [ps.cryptography]) );

in perSystem.self.mkScript {

  name = "to";
  path = [ gnugrep python3 openssh rage ssh-to-age ];
  text = ''
    source ${flake.lib.bash}
    case ''${1-} in
      age | a)
        ${readFile ./to-age.sh}
        ;;
      hex | h)
        exec python3 ${./to-hex.py} "''${@:2}"
        ;;
      public | p)
        ${readFile ./to-public.sh}
        ;;
      ssh | s)
        exec python3 ${./to-ssh.py}
        ;;
      help | *)
        echo
        echo "Usage:  to COMMAND [ARGS]"
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
