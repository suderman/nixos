{ flake, pkgs, perSystem, ... }: let

  inherit (builtins) readFile;
  inherit (pkgs) eza git inetutils iptables netcat rage;
  inherit (perSystem.self) derive ipaddr;

in perSystem.self.mkScript {

  name = "ssh-key";
  path = [ derive eza git inetutils ipaddr iptables netcat rage ];

  # Derivation path for key
  env = { inherit (flake) derivationPath; };

  text = ''
    source ${flake.lib.bash}

    # First arg is command: build|receive|send
    command=''${1-}

    # Second arg is HOST or REBOOT
    host=''${2-}
    reboot=''${2-}

    # Third arg is IP
    ip=''${3-}

    case "$command" in
      build | b)
        ${readFile ./build.sh}
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
        echo "Usage: ssh-key COMMAND"
        echo
        echo "  build"
        echo "  receive"
        echo "  send [HOST] [IP]"
        echo "  verify"
        echo "  help"
        ;;
    esac
    echo
  '';

}
