{
  pkgs,
  perSystem,
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

  # Bash script
  text = builtins.readFile ./sshed.sh;
}
