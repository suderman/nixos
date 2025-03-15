{ flake, pkgs, perSystem, ... }: let

  inherit (builtins) readFile;
  inherit (pkgs) git netcat rage smenu;
  inherit (perSystem.self) derive ipaddr;

in perSystem.self.mkScript {

  name = "ssh-key";
  path = [ derive git ipaddr netcat rage smenu ];

  # Derivation path for key
  env = { inherit (flake) derivationPath; };

  text = ''
    source ${flake.lib.bash}

    # First arg is command: build|receive|send
    command=''${1-}

    # Second arg is IP
    ip=''${2-}

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
      help | *)
        echo "Usage: ssh-key COMMAND"
        echo
        echo "  build"
        echo "  receive"
        echo "  send [IP]"
        echo "  help"
        ;;
    esac
    echo
  '';

}
