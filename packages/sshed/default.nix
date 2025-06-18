{ flake, pkgs, perSystem, ... }: let

  inherit (builtins) readFile;
  inherit (pkgs) eza git gnugrep inetutils iptables netcat age;
  inherit (perSystem.self) derive ipaddr;

in perSystem.self.mkScript {

  name = "sshed";
  path = [ derive eza git gnugrep inetutils ipaddr iptables netcat age ];

  # Derivation path for key
  env.derivation_path = "bip85-hex32-index${toString flake.derivationIndex}";

  text = ''
    source ${flake.lib.bash}

    # First arg is command: generate|receive|send
    command=''${1-}

    # Second arg is HOST or REBOOT
    host=''${2-}
    reboot=''${2-}

    # Third arg is IP
    ip=''${3-}

    case "$command" in
      generate | g)
        ${readFile ./generate.sh}
        ;;
      receive | r)
        ${readFile ./receive.sh}
        ;;
      send | s)
        ${readFile ./send.sh}
        ;;
      verify | v)
        ${readFile ./verify.sh}
        ;;
      help | *)
        echo "Usage: sshed COMMAND"
        echo
        echo "  generate"
        echo "  receive"
        echo "  send [HOST] [IP]"
        echo "  verify"
        echo "  help"
        ;;
    esac
  '';

}
