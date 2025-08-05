{
  pkgs,
  perSystem,
  flake,
  ...
}: let
  inherit (builtins) readFile;
  inherit (pkgs) git gnugrep gum inetutils iptables netcat age;
  inherit (perSystem.self) derive ipaddr;
in
  perSystem.self.mkScript {
    name = "sshed";
    path = [derive git gnugrep gum inetutils ipaddr iptables netcat age];

    # Derivation path for key
    env.derivation_path = "bip85-hex32-index${toString flake.derivationIndex}";

    # Bash script
    text = readFile ./sshed.sh;
  }
