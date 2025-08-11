{
  pkgs,
  perSystem,
  ...
}:
perSystem.self.mkScript {
  name = "nixos";
  path = [
    perSystem.self.derive
    perSystem.self.ipaddr
    pkgs.age
    pkgs.alejandra
    pkgs.git
    pkgs.gnugrep
    pkgs.gum
    pkgs.inetutils
    pkgs.iptables
    pkgs.netcat
    pkgs.passh
    pkgs.qemu
  ];

  # Bash script
  text = builtins.readFile ./nixos.sh;
}
