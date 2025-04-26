{ flake, pkgs, perSystem, ... }: perSystem.self.mkScript {

  path = with pkgs; [ curl gawk iproute2 ];
  name = "ipaddr";
  text = ''
    case "''${1-}" in
      lan | l)
        lan="$(ip -4 a | awk '/state UP/{flag=1} flag && /inet /{split($2, ip, "/"); print ip[1]; exit}')"
        vpn="$(ip -4 a | awk '/tailscale0/{flag=1} flag && /inet /{split($2, ip, "/"); print ip[1]; exit}')"
        if [[ -z "$vpn" ]]; then 
          echo "$lan"
        elif [[ $lan == 10.0.2.* ]]; then 
          echo "127.0.0.1"
        else
          echo "$lan"
        fi
        ;;
      wan | w)
        curl -s ipv4.icanhazip.com
        ;;
      help | *)
        echo "Usage: ipaddr CONTEXT"
        echo
        echo "  lan"
        echo "  wan"
        echo "  help"
        ;;
    esac
    echo
  '';

}
