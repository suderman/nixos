{
  pkgs,
  perSystem,
  flake,
  ...
}:
perSystem.self.mkScript {
  name = "sshed";
  path = [
    perSystem.self.agenix
    perSystem.self.derive
    perSystem.self.ipaddr
    pkgs.git
    pkgs.gnugrep
    pkgs.gum
    pkgs.inetutils
    pkgs.iptables
    pkgs.netcat
  ];

  # Derivation path for key
  env.derivation_path = "bip85-hex32-index${toString flake.derivationIndex}";

  # Bash script
  text = builtins.readFile ./sshed.sh;
}
