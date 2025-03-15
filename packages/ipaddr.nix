{ flake, pkgs, perSystem, ... }: perSystem.self.mkScript {

  path = with pkgs; [ curl gawk iproute2 ];
  name = "ipaddr";
  text = ''
    case "''${1-}" in
      local | l)
        lan="$(ip -4 a | awk '/state UP/{flag=1} flag && /inet /{split($2, ip, "/"); print ip[1]; exit}')"
        vpn="$(ip -4 a | awk '/tailscale0/{flag=1} flag && /inet /{split($2, ip, "/"); print ip[1]; exit}')"
        echo "$([ -z "$vpn" ] || [[ $lan == 10.0.2.* ]] && echo "$vpn" || echo "$lan")"
        ;;
      public | p)
        curl -s ipv4.icanhazip.com
        ;;
      help | *)
        echo "Usage: ipaddr CONTEXT"
        echo
        echo "  local"
        echo "  public"
        echo "  help"
        ;;
    esac
    echo
  '';

}
