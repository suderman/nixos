{
  pkgs,
  perSystem,
  ...
}:
perSystem.self.mkScript {
  name = "nixos";
  path = [
    perSystem.self.agenix
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

  # Path to template files
  env = {
    templates = ./templates;
  };

  # Bash script
  text = builtins.readFile ./nixos.sh;
}
